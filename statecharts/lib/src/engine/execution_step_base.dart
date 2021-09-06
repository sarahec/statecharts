import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:statecharts/statecharts.dart';

/// Contains the results of one execution step.
///
/// This uses [built_value](https://pub.dev/packages/built_value) to create
/// an immutable object which, when asked to change a value, creates a
/// modified copy. This makes debugging easier, including the ability to
/// roll back the engine to a prior step by loading this object.
///
class ExecutionStepBase<T> implements ExecutionStep<T> {
  StateTree<T> get tree => workingTree;

  @visibleForOverriding
  final MutableStateTree<T> workingTree;

  ExecutionStepBase._(this.workingTree, [this._history = const {}]);

  Map<String, Iterable<State<T>>> get history => _history;

  final _history;

  @override
  Iterable<State<T>> get entryStates => _entryStates.sorted;

  @override
  Iterable<State<T>> get exitStates => _exitStates.reverseSorted;

  @override
  Iterable<State<T>> get activeStates => workingTree.toIterable;

  final _exitStates = <State<T>>{};
  final _entryStates = <State<T>>{};

  /// Initialized using [RootState.initialTransition].
  factory ExecutionStepBase(RootState<T> root) {
    final selections =
        root.initialTransition?.targetStates ?? [root.substates.first];
    return ExecutionStepBase._(MutableStateTree(root))
      ..workingTree.addSelections(selections);
  }

  @override
  ExecutionStep<T> applyTransitions(Iterable<Transition<T>> transitions) =>
      applyChanges(
        remove: transitions.map((t) => t.source!),
        add: transitions.map((t) => t.targetStates).expand((s) => s),
        transitions: transitions,
      );

  /// The smallest possible subtree containing all the transition targets.
  State<T>? getTransitionDomain(Transition<T> t) {
    final tstates = getEffectiveTargetStates(t);
    if (tstates.isEmpty) {
      return null;
    }
    if (t.type == TransitionType.Internal &&
        t.source!.isCompound &&
        tstates.every((s) => s.descendsFrom(t.source!))) {
      return t.source;
    }
    return State.commonSubtree([t.source!, ...tstates]);
  }

  Set<State<T>> computeExitSet(Iterable<Transition<T>> transitions) {
    final statesToExit = <State<T>>{};
    final configuration = Set.of(workingTree.toIterable);
    for (var t in transitions) {
      final domain = getTransitionDomain(t);
      if (domain != null) {
        for (var cs in configuration) {
          if (cs.descendsFrom(domain)) {
            statesToExit.add(cs);
          }
        }
      }
    }
    return statesToExit;
  }

  /// Returns the states that will be the target when 'transition' is taken, dereferencing any history states.
  Set<State<T>> getEffectiveTargetStates(transition) {
    var targets = <State<T>>{};
    for (var s in transition.targetStates) {
      if (s is HistoryState) {
        if (history.containsKey(s.id)) {
          targets = targets.union(Set.of(history[s.id]!));
        } else {
          targets = targets.union(getEffectiveTargetStates(s.transition));
        }
      } else {
        targets.add(s);
      }
    }
    return targets;
  }

  /// Create a new step after adding and removing states.
  @override
  ExecutionStep<T> applyChanges({
    Iterable<State<T>> remove = const [],
    Iterable<State<T>> add = const [],
    Iterable<Transition<T>>? transitions,
  }) {
    if (changeSubtrees && remove.isNotEmpty) {
      workingTree.removeSubtree(State.commonSubtree(remove));
    }
  }

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
  void addToTree(State<T> node) {
    if (node.parent != null) {
      workingTree[node.parent!] = node;
    }
  }

  @visibleForOverriding
  void addAllToTree(Iterable<State<T>> nodes) {
    for (var node in nodes) {
      addToTree(node);
    }
  }

  @visibleForOverriding
  Iterable<State<T>> buildTree(Iterable<State<T>> selections,
      {State<T>? startNode}) {
    final baseNode = startNode ?? root;

    // Build links back to the starting node from known states
    void _expandSelected(_selections, State<T> top) {
      addAllToTree(_selections);
      for (var s in _selections) {
        addAllToTree(s.ancestors(upTo: top));
      }
    }

    void _addSubtree(State<T> state) {
      var probe = state;

      while (true) {
        addToTree(probe);
        if (probe.isAtomic) return;

        // Move to the substate(s)
        if (probe.isParallel) {
          for (var s
              in probe.substates.where((s) => !workingTree.containsKey(s))) {
            _addSubtree(s);
          }
        } else {
          // Find the active substate(s)
          final _selections = state.initialTransition?.targetStates;
          if (_selections == null) {
            probe = state.substates.first;
          } else {
            addAllToTree(buildTree(_selections, startNode: state));
            return;
          }
        }
      }
    }

    if (selections.isEmpty) {
      _addSubtree(baseNode);
      return workingTree.keys;
    }

    final concreteSelections = replaceHistoryStates(selections);
    _expandSelected(concreteSelections, baseNode);
    for (var s in concreteSelections.where((s) => s.isCompound)) {
      _addSubtree(s);
    }
    return workingTree.keys;
  }
}
