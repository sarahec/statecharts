import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:collection/collection.dart';
import 'package:statecharts/statecharts.dart';

part 'execution_step.g.dart';

/// Contains the results of one execution step.
///
/// This uses [built_value](https://pub.dev/packages/built_value) to create
/// an immutable object which, when asked to change a value, creates a
/// modified copy. This makes debugging easier, including the ability to
/// roll back the engine to a prior step by loading this object.
///
abstract class ExecutionStep<T>
    implements Built<ExecutionStep<T>, ExecutionStepBuilder<T>> {
  factory ExecutionStep([void Function(ExecutionStepBuilder<T>) updates]) =
      _$ExecutionStep<T>;

  /// Generates the initial execution step using [RootState.initialTransition].
  ///
  /// If there's no initial transition, select the first substate under
  /// the.
  static ExecutionStep<T> initial<T>(RootState<T> root) {
    // Collect all the explicit initial states
    final initialStates = <State<T>>{};
    for (var s in root.toIterable.where((probe) => probe.isCompound)) {
      if (s.initialTransition == null) continue;
      initialStates.addAll(s.initialTransition!.targetStates);
    }
    return ExecutionStep<T>((b) => b
      ..root = root
      ..selections.addAll(initialStates));
  }

  // Required by built_value
  ExecutionStep._();

  /// All active states, including resolved history states.
  @memoized
  Set<State<T>> get activeStates {
    final result = <State<T>>{};
    if (selections.none((s) => s is HistoryState)) {
      // No histories
      result.addAll(selections);
      result.addAll(root.activeDescendents(selections.asSet()));
    } else {
      final _history = priorHistory;
      final _historyStates = selections.whereType<HistoryState<T>>();
      final _newSelections =
          Set.of(selections.whereNot((s) => s is HistoryState<T>));
      for (var hs in _historyStates) {
        final id = hs.parent!.id!;
        if (_history.containsKey(id)) {
          _newSelections.addAll(_history[id]!);
        } else {
          _newSelections.addAll(hs.transition.targetStates);
        }
      }
      result.addAll(_newSelections);
      result.addAll(root.activeDescendents(_newSelections));
    }
    return UnmodifiableSetView(result);
  }

  /// All states that need [State.onEntry] called, in order.
  @memoized
  Iterable<State<T>> get entryStates =>
      activeStates.difference(priorStep?.activeStates ?? {}).toList()
        ..sort((a, b) => a.order - b.order);

  /// All states that need [State.onExit] called, in order.
  @memoized
  Iterable<State<T>> get exitStates => priorStep == null
      ? []
      : (priorStep!.activeStates.difference(activeStates).toList()
        ..sort((a, b) => a.order - b.order));

  /// History from the prior step, or an empty set if no prior step.
  @memoized
  BuiltMap<String, Iterable<State<T>>> get priorHistory =>
      priorStep?.history ?? BuiltMap<String, Iterable<State<T>>>();

  /// Updates the history map to include exit states that need to record
  /// the prior active configuration (i.e. they contain a history state).
  @memoized
  BuiltMap<String, Iterable<State<T>>> get history {
    if (priorStep == null) {
      return BuiltMap<String, Iterable<State<T>>>();
    }
    final b = priorHistory.toBuilder();
    for (var s in exitStates.where((s) => s.containsHistoryState)) {
      b[s.id!] = historyValuesFor(s);
    }
    return b.build();
  }

  /// True if any values have changed in this step.
  @memoized
  bool get isChanged =>
      priorStep == null ||
      !SetEquality().equals(selections.asSet(), priorStep!.selections.asSet());

  /// Link back to the previous step.
  ExecutionStep<T>? get priorStep;

  /// The root of the tree
  RootState<T> get root;

  /// The set of active states.
  BuiltSet<State<T>> get selections;

  /// The transitions taken.
  Iterable<Transition<T>>? get transitions;

  /// Generates the history entry for a subtree.
  Iterable<State<T>> historyValuesFor(State<T> s) {
    assert(s.containsHistoryState);
    // Since this is called for states that are exiting, we have to use the prior active states
    final priorActive = priorStep?.activeStates ?? <State<T>>{};
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
}
