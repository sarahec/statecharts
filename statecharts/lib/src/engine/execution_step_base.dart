import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:statecharts/statecharts.dart';

part 'execution_step_base.g.dart';

/// Contains the results of one execution step.
///
/// This uses [built_value](https://pub.dev/packages/built_value) to create
/// an immutable object which, when asked to change a value, creates a
/// modified copy. This makes debugging easier, including the ability to
/// roll back the engine to a prior step by loading this object.
///
abstract class ExecutionStepBase<T>
    implements
        ExecutionStep<T>,
        Built<ExecutionStepBase<T>, ExecutionStepBaseBuilder<T>> {
  factory ExecutionStepBase(
          [void Function(ExecutionStepBaseBuilder<T>) updates]) =
      _$ExecutionStepBase<T>;

  /// Generates the initial execution step using [RootState.initialTransition].
  ///
  /// If there's no initial transition, select the first substate under
  /// the.
  static ExecutionStepBase<T> initial<T>(RootState<T> root) {
    // Collect all the explicit initial states
    final initialStates = <State<T>>{};
    for (var s in root.toIterable.where((probe) => probe.isCompound)) {
      if (s.initialTransition == null) continue;
      initialStates.addAll(s.initialTransition!.targetStates);
    }
    return ExecutionStepBase<T>((b) => b
      ..root = root
      ..selections = initialStates
      ..priorActiveStates = {}
      ..priorHistory = MapBuilder<String, Iterable<State<T>>>());
  }

  @override
  ExecutionStepBase<T> applyTransitions(Iterable<Transition<T>> transitions) =>
      applyChanges(
        remove: transitions.map((t) => t.source!),
        add: transitions.map((t) => t.targetStates).expand((s) => s),
        transitions: transitions,
      );

  /// Create a new step after adding and removing states.
  @override
  ExecutionStepBase<T> applyChanges({
    Iterable<State<T>> remove = const [],
    Iterable<State<T>> add = const [],
    Iterable<Transition<T>>? transitions,
  }) {
    final b = toBuilder();
    b.priorActiveStates = activeStates;
    b.priorHistory = history.toBuilder();
    b.transitions = transitions ?? [];
    b.selections = Set.of(selections)
      ..removeAll(remove)
      ..addAll(add);
    return b.build();
  }

  /// Active states from the last step
  Set<State<T>> get priorActiveStates;

  // Required by built_value
  ExecutionStepBase._();

  /// All active states, including resolved history states.
  ///
  /// This rebuilds the entire tree from scratch (for now)
  @override
  @memoized
  Set<State<T>> get activeStates =>
      UnmodifiableSetView<State<T>>(buildTree(selections));

  /// All states that need [State.onEntry] called, in order.
  @override
  @memoized
  Iterable<State<T>> get entryStates =>
      activeStates.difference(priorActiveStates ?? {}).toList()
        ..sort((a, b) => a.order - b.order);

  /// All states that need [State.onExit] called, in reverse order.
  @override
  @memoized
  Iterable<State<T>> get exitStates =>
      (priorActiveStates.difference(activeStates).toList()
        ..sort((a, b) => b.order - a.order));

  /// History from the prior step, or an empty set if no prior step.
  BuiltMap<String, Iterable<State<T>>> get priorHistory;

  /// Updates the history map to include exit states that need to record
  /// the prior active configuration (i.e. they contain a history state).
  @memoized
  BuiltMap<String, Iterable<State<T>>> get history {
    final b = priorHistory.toBuilder();
    for (var s in exitStates.where((s) => s.containsHistoryState)) {
      b[s.id!] = historyValuesFor(s);
    }
    return b.build();
  }

  /// True if any values have changed in this step.
  @override
  @memoized
  bool get isChanged => !SetEquality().equals(activeStates, priorActiveStates);

  /// The root of the tree
  @override
  RootState<T> get root;

  /// Explicitly selected states (from transitions)
  @override
  Set<State<T>> get selections;

  /// The transitions taken.
  @override
  Iterable<Transition<T>>? get transitions;

  /// Generates the history entry for a subtree.
  @visibleForOverriding
  Iterable<State<T>> historyValuesFor(State<T> s) {
    assert(s.containsHistoryState);
    // Since this is called for states that are exiting, we have to use the prior active states
    final priorActive = priorActiveStates;
    final activeChildren =
        s.substates.where((probe) => priorActive.contains(probe));
    final historyChildren = s.substates.whereType<HistoryState>();
    // From the spec:
    // If the 'type' of a <history> element is "shallow", the SCXML processor
    // must record the immediately active children of its parent before taking
    // any transition that exits the parent. If the 'type' of a <history>
    // element is "deep", the SCXML processor must record the active atomic
    // descendants of the parent before taking any transition that exits the
    // parent.
    //
    // Note that in a conformant SCXML document, a <state> or <parallel>
    // element may have both "deep" and "shallow" <history> children.
    final result = <State<T>>{};
    for (var hs in historyChildren) {
      if (hs.type == HistoryDepth.SHALLOW) {
        result.addAll(activeChildren);
      } else {
        final deepChildren = [
          for (var c in activeChildren) c.activeDescendents(priorActive).last
        ];
        result.addAll(deepChildren);
      }
    }
    return result;
  }

  @visibleForOverriding
  Iterable<State<T>> replaceHistoryStates(Iterable<State<T>> selections) {
    final _historyStates = selections.whereType<HistoryState<T>>();
    if (_historyStates.isEmpty) return selections;
    final concreteStates = selections.toSet();
    concreteStates.removeAll(_historyStates);
    for (var h in _historyStates) {
      concreteStates.addAll(priorHistory[h] ?? h.transition.targetStates);
    }
    return concreteStates;
  }

  @visibleForOverriding
  Set<State<T>> buildTree(Iterable<State<T>> selections,
      {State<T>? startNode}) {
    final tree = <State<T>>{};
    final baseNode = startNode ?? root;

    // Build links back to the starting node from known states
    void _expandSelected(_selections, State<T> top) {
      tree.addAll(_selections);
      for (var s in _selections) {
        tree.addAll(s.ancestors(upTo: top));
      }
    }

    void _addSubtree(State<T> state) {
      var probe = state;

      while (true) {
        tree.add(probe);
        if (probe.isAtomic) return;

        // Move to the substate(s)
        if (probe.isParallel) {
          for (var s in probe.substates.where((s) => !tree.contains(s))) {
            _addSubtree(s);
          }
        } else {
          // Find the active substate(s)
          final _selections = state.initialTransition?.targetStates;
          if (_selections == null) {
            probe = state.substates.first;
          } else {
            tree.addAll(buildTree(_selections, startNode: state));
            return;
          }
        }
      }
    }

    if (selections.isEmpty) {
      _addSubtree(baseNode);
      return tree;
    }

    final concreteSelections = replaceHistoryStates(selections);
    _expandSelected(concreteSelections, baseNode);
    for (var s in concreteSelections.where((s) => s.isCompound)) {
      _addSubtree(s);
    }
    tree.add(baseNode);
    return tree;
  }
}
