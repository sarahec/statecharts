// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//
//      https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:meta/meta.dart';
import 'package:statecharts/statecharts.dart';

/// Contains the results of one execution step.
class ExecutionStep<T> {
  /// History values used in this step
  final History<T> history;

  final Iterable<Transition<T>> transitions;

  final RootState<T> root;
  final Iterable<State<T>> activeStates,
      entryStates,
      exitStates,
      defaultEntryStates;
  final Map<State<T>, Transition<T>> defaultHistoryActions;
  final T? context;

  ExecutionStep(this.root, this.context, this.history,
      {this.transitions = const [],
      this.activeStates = const [],
      this.entryStates = const [],
      this.exitStates = const [],
      this.defaultEntryStates = const [],
      this.defaultHistoryActions = const {}});

  ExecutionStepBuilder<T> toBuilder() =>
      ExecutionStepBuilder(root, history, activeStates);
}

class ExecutionStepBuilder<T> {
  /// The root of the tree (statechart).
  final RootState<T> root;
  late final HistoryBuilder<T> history;
  late final StateSet<T> activeStates;
  late final StateSet<T> _statesToEnter, _statesForDefaultEntry, _statesToExit;
  final _defaultHistoryActions = <State<T>, Transition<T>>{};
  late final Iterable<Transition<T>> transitions;

  ExecutionStepBuilder(this.root, History<T> priorHistory,
      [Iterable<State<T>> priorStates = const []]) {
    activeStates = StateSet(root)
      ..addAll(priorStates)
      ..unmodifiable;
    history = priorHistory.toBuilder();
    _statesToEnter = StateSet(root);
    _statesForDefaultEntry = StateSet(root);
    _statesToExit = StateSet(root);
  }

  /// States that require their default initializers, in order.
  Iterable<State<T>> get statesForDefaultEntry => _statesForDefaultEntry;

  /// States that require their default initializers as a result of resolving history, in order.
  // Map<State<T>, Transition<T>> get defaultHistoryActions =>
  //     _defaultHistoryActions;

  /// States that require [onEnter], in order.
  Iterable<State<T>> get statesToEnter => _statesToEnter;

  /// States that require [onExit], in order.
  Iterable<State<T>> get statesToExit => _statesToExit;

  /// Walks up the tree collecting states to enter.
  ///
  /// If this sees a parallel state on the way up, will also collect that
  /// state's descendents.
  @visibleForTesting
  void addAncestorStatesToEnter(State<T> state, [State<T>? ancestor]) {
    for (var anc in state.ancestors(upTo: ancestor)) {
      if (anc is RootState<T>) continue;
      _statesToEnter.add(anc);
      if (anc.isParallel) {
        for (var child in anc.substates) {
          if (!_statesToEnter.any((s) => s.descendsFrom(child))) {
            addDescendantStatesToEnter(child);
          }
        }
      }
    }
  }

  /// Selects active descendents, substituting history values when necessary.
  @visibleForTesting
  void addDescendantStatesToEnter(State<T> state) {
    if (state is HistoryState<T>) {
      final parent = state.parent!;
      if (history.contains(parent)) {
        final historyValue = history[parent]!;
        for (var s in historyValue) {
          addDescendantStatesToEnter(s);
        }
        for (var s in historyValue) {
          addAncestorStatesToEnter(s, state.parent);
        }
      } else {
        _defaultHistoryActions[state.parent!] = state.transition;
        for (var s in state.transition.targetStates) {
          addDescendantStatesToEnter(s);
        }
        for (var s in state.transition.targetStates) {
          addAncestorStatesToEnter(s, state.parent);
        }
      }
      return; // HistoryState
    }
    // Non-history state
    _statesToEnter.add(state);
    if (state.isParallel) {
      for (var child in state.substates) {
        if (!_statesToEnter.any((s) => s.descendsFrom(child))) {
          addDescendantStatesToEnter(child);
        }
      }
    } else if (state.isCompound) {
      _statesForDefaultEntry.add(state);
      for (var s in state.initialStates) {
        addDescendantStatesToEnter(s);
        addAncestorStatesToEnter(s, state);
      }
    }
  }

  /// Populates [statesToEnter], [statesToExit], [statesForDefaultEntry], and [historyStatesForDefaltEntry].
  ///
  /// You can only call this once per builder instance.
  void applyTransitions(Iterable<Transition<T>> selectedTransitions) {
    transitions = removeConflictingTransitions(selectedTransitions);
    computeEntrySet(transitions);
    computeExitSet(transitions);
  }

  ExecutionStep<T> build([T? context]) =>
      ExecutionStep(root, context, history.build(),
          transitions: transitions,
          activeStates: activeStates.toSet()
            ..addAll(_statesToEnter) // includes default entry states
            ..removeAll(_statesToExit),
          entryStates: _statesToEnter,
          defaultEntryStates: _statesForDefaultEntry,
          exitStates: _statesToExit,
          defaultHistoryActions: _defaultHistoryActions);

  /// Computes [statesToEnter] and [statesForDefaultEntry] using the transitions.
  @visibleForTesting
  void computeEntrySet(Iterable<Transition<T>> transitions) {
    for (var t in transitions) {
      for (var s in t.targetStates) {
        addDescendantStatesToEnter(s);
      }
      final ancestor = getTransitionDomain(t);
      for (var s in getEffectiveTargetStates(t)) {
        addAncestorStatesToEnter(s, ancestor);
      }
    }
  }

  /// Computes [statesToExit] using the transitions.
  @visibleForTesting
  StateSet<T> computeExitSet(Iterable<Transition<T>> transitions) {
    for (var t in transitions.where((t) => t.targetStates.isNotEmpty)) {
      final domain = getTransitionDomain(t)!;
      for (var s in activeStates) {
        if (s.descendsFrom(domain)) {
          _statesToExit.add(s);
        }
      }
    }
    return _statesToExit;
  }

  /// All targets of 'transition' after replacing any history states.
  @visibleForOverriding
  Set<State<T>> getEffectiveTargetStates(transition) {
    var targets = <State<T>>{};
    for (var s in transition.targetStates) {
      if (s is HistoryState<T>) {
        if (history.contains(s)) {
          targets.addAll(Set.of(history[s]!));
        } else {
          targets.addAll(getEffectiveTargetStates(s.transition));
        }
      } else {
        targets.add(s);
      }
    }
    return targets;
  }

  /// The smallest possible subtree containing all the transition targets.
  @visibleForOverriding
  State<T>? getTransitionDomain(Transition<T> t) {
    final tstates = getEffectiveTargetStates(t);
    if (tstates.isEmpty) {
      return null;
    }
    if (t.type == TransitionType.internalTransition &&
        t.source!.isCompound &&
        tstates.every((s) => s.descendsFrom(t.source!))) {
      return t.source;
    }
    return State.commonSubtree([t.source!, ...tstates]);
  }

  @visibleForTesting
  Iterable<State<T>> historyValuesFor(State<T> s, StateSet<T> context) {
    final result = StateSet<T>(root);
    for (var hs in s.substates.whereType<HistoryState>()) {
      if (hs.type == HistoryDepth.shallow) {
        result.addAll(s.substates.where((probe) => context.contains(probe)));
      } else {
        result.addAll(
            context.where((probe) => probe.isAtomic && probe.descendsFrom(s)));
      }
    }
    return result.toList();
  }

  /// True if this parent state has an active final child.
  @visibleForTesting
  bool isInFinalState(State<T> s) => s.isCompound
      ? s.substates.any((s) => s.isFinal && activeStates.contains(s))
      : s.isParallel
          ? s.substates.every((s) => isInFinalState(s))
          : false;

  /// Selects for the highest targets in the tree (only needed when transitions
  /// come from a parallel state).
  @visibleForTesting
  Iterable<Transition<T>> removeConflictingTransitions(
      Iterable<Transition<T>> enabledTransitions) {
    if (enabledTransitions.length <= 1) return enabledTransitions;

    // We have multiple transitions, which will happen when triggering
    // an event on a parallel state.
    final filteredTransitions = <Transition<T>>{};
    //toList sorts the transitions in the order of the states that selected them
    for (var t1 in enabledTransitions.sorted) {
      var t1Preempted = false;
      final transitionsToRemove = <Transition<T>>{};
      for (var t2 in filteredTransitions.sorted) {
        if (computeExitSet([t1])
            .intersection(computeExitSet([t2]))
            .isNotEmpty) {
          if (t1.source!.descendsFrom(t2.source!)) {
            transitionsToRemove.add(t2);
          } else {
            t1Preempted = true;
            break;
          }
        }
      }
      if (!t1Preempted) {
        filteredTransitions.removeAll(transitionsToRemove);
      }
      filteredTransitions.add(t1);
    }
    return filteredTransitions.sorted;
  }

  /// Saves the current state of s to history (if s contains a history state).
  void saveHistory(State<T> s) {
    if (!s.containsHistoryState) return;
    final values = historyValuesFor(s, activeStates);
    history.add(s, values);
  }
}
