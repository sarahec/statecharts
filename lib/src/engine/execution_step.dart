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

  factory ExecutionStep.initial(RuntimeState<T> root) {
    final allNodes = List.of(root.toIterable, growable: false);
    // Collect all the explicit initial states
    final initialStates = <RuntimeState<T>>{};
    for (var s in allNodes.where((probe) => probe.isCompound)) {
      final refs = s.initialRefs ?? s.initialTransition?.targets ?? [];
      late final states;
      try {
        states =
            refs.map((ref) => allNodes.firstWhere((probe) => probe.id == ref));
      } catch (_) {
        _log.warning('Could not find target of initial reference in $s');
      }
      assert(!states.all((probe) => probe.descendsFrom(s)),
          'ERROR: Initialization target lies outside descendents of $s');
    }
    return ExecutionStep((b) => b
      ..root = root
      ..selections.addAll(initialStates));
  }

  ExecutionStep._();

  @memoized
  Set<RuntimeState<T>> get activeStates {
    final _activeStates = <RuntimeState<T>>{};
    for (var s in selections) {
      _activeStates.addAll(s.ancestors());
    }
    for (var s in selections) {
      _activeStates.addAll(s.activeDescendents(selections.asSet()));
    }
    return UnmodifiableSetView(_activeStates);
  }

  @memoized
  Iterable<RuntimeState<T>> get entryStates =>
      activeStates.difference(priorStep?.activeStates ?? {}).toList()
        ..sort((a, b) => a.order - b.order);

  @memoized
  Iterable<RuntimeState<T>> get exitStates => priorStep == null
      ? []
      : (priorStep!.activeStates.difference(activeStates).toList()
        ..sort((a, b) => a.order - b.order));

  @memoized
  BuiltMap<String, Iterable<RuntimeState<T>>> get history {
    if (priorStep == null) {
      return BuiltMap<String, Iterable<RuntimeState<T>>>();
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

  RuntimeState<T> get root;

  BuiltSet<RuntimeState<T>> get selections;

  Iterable<RuntimeTransition<T>>? get transitions;

  Iterable<RuntimeState<T>> historyValuesFor(RuntimeState<T> s) {
    assert(s.containsHistoryState);
    assert(priorStep != null);
    // Since this is called for states that are exiting, we have to use the prior active states
    final priorActive = priorStep!.activeStates;
    final activeChildren =
        s.substates.where((probe) => priorActive.contains(probe));
    final historyChildren = s.substates.where((probe) => probe.isHistoryState);
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
    final result = <RuntimeState<T>>{};
    for (var hs in historyChildren) {
      if ((hs.state as HistoryState).type == HistoryDepth.SHALLOW) {
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
