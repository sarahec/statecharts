import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:collection/collection.dart';
import 'package:logging/logging.dart';
import 'package:statecharts/statecharts.dart';

part 'execution_step.g.dart';

final _log = Logger('execution_step');

abstract class ExecutionStep<T>
    implements Built<ExecutionStep<T>, ExecutionStepBuilder<T>> {
  factory ExecutionStep([void Function(ExecutionStepBuilder<T>) updates]) =
      _$ExecutionStep<T>;

  factory ExecutionStep.initial(RootState<T> root) {
    final allNodes = List.of(root.toIterable, growable: false);
    // Collect all the explicit initial states
    final initialStates = <State<T>>{};
    for (var s in allNodes.where((probe) => probe.isCompound)) {
      if (s.initialTransition != null) {
        initialStates.addAll(s.initialTransition!.targets);
      }
    }
    return ExecutionStep((b) => b
      ..root = root
      ..selections.addAll(initialStates));
  }

  ExecutionStep._();

  @memoized
  Set<State<T>> get activeStates {
    final _activeStates = <State<T>>{};
    _activeStates.addAll(selections);
    _activeStates.addAll(root.activeDescendents(selections.asSet()));
    return UnmodifiableSetView(_activeStates);
  }

  @memoized
  Iterable<State<T>> get entryStates =>
      activeStates.difference(priorStep?.activeStates ?? {}).toList()
        ..sort((a, b) => a.order - b.order);

  @memoized
  Iterable<State<T>> get exitStates => priorStep == null
      ? []
      : (priorStep!.activeStates.difference(activeStates).toList()
        ..sort((a, b) => a.order - b.order));

  @memoized
  BuiltMap<String, Iterable<State<T>>> get history {
    if (priorStep == null) {
      return BuiltMap<String, Iterable<State<T>>>();
    }
    final b = priorStep!.history.toBuilder();
    for (var s in exitStates.where((s) => s.containsHistoryState)) {
      b[s.id!] = historyValuesFor(s);
    }
    return b.build();
  }

  bool get isUnchanged =>
      priorStep != null &&
      SetEquality().equals(selections.asSet(), priorStep!.selections.asSet());

  ExecutionStep<T>? get priorStep;

  State<T> get root;

  BuiltSet<State<T>> get selections;

  Iterable<Transition<T>>? get transitions;

  Iterable<State<T>> historyValuesFor(State<T> s) {
    assert(s.containsHistoryState);
    assert(priorStep != null);
    // Since this is called for states that are exiting, we have to use the prior active states
    final priorActive = priorStep!.activeStates;
    final activeChildren =
        s.substates.where((probe) => priorActive.contains(probe));
    final historyChildren = s.substates.whereType<HistoryState>();
    late final deepChildren;
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
        deepChildren ??= [
          for (var c in activeChildren) c.activeDescendents(priorActive).last
        ];
        result.addAll(deepChildren);
      }
    }
    return result;
  }
}
