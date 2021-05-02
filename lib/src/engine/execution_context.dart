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

import 'dart:collection';

import 'package:meta/meta.dart';
import 'package:statecharts/statecharts.dart';

class ExecutionContext<T> {
  final RuntimeState<T> root;
  final Map<String, Iterable<RuntimeState<T>>> historyValues;
  final LinkedHashSet<RuntimeState<T>> configuration;

  var _defaultHistoryContent;

  /// Every state that requires `state.enter(context)`
  final _statesToEnter = <RuntimeState<T>>[];

  /// Every state that requires `state.enter(context)` on its default initial state
  final _statesForDefaultEntry = <RuntimeState<T>>[];

  ExecutionContext(this.root, this.configuration, this.historyValues);

  @visibleForTesting
  int documentOrder(a, b) => a.order.compareTo(b.order);

  Iterable<RuntimeTransition<T>> selectTransitions(String? event, T? context) {
    var enabledTransitions = <RuntimeTransition<T>>{};
    final atomicStates = configuration.where((s) => s.isAtomic).toList()
      ..sort(documentOrder);
    for (var state in atomicStates) {
      for (var s in [state, ...getProperAncestors(state)]) {
        for (var t in s.transitions) {
          // n.b. assumes sorting in document order for transitions
          if (t.matches(anEvent: event, context: context)) {
            enabledTransitions.add(t);
            break;
          }
        }
      }
    }
    enabledTransitions = removeConflictingTransitions(enabledTransitions);
    return enabledTransitions;
  }

  Set<RuntimeTransition<T>> removeConflictingTransitions(
      Iterable<RuntimeTransition<T>> enabledTransitions) {
    final filteredTransitions = <RuntimeTransition<T>>{};
    //toList sorts the transitions in the order of the states that selected them
    for (var t1 in enabledTransitions) {
      var t1Preempted = false;
      final transitionsToRemove = <RuntimeTransition<T>>{};
      for (var t2 in filteredTransitions) {
        if (computeExitSet([t1])
            .intersection(computeExitSet([t2]))
            .isNotEmpty) {
          if (isDescendant(t1.source, t2.source)) {
            transitionsToRemove.add(t2);
          } else {
            t1Preempted = true;
            break;
          }
        }
      }
      if (!t1Preempted) {
        for (var t3 in transitionsToRemove) {
          filteredTransitions.remove(t3);
        }
        filteredTransitions.add(t1);
      }
    }
    return filteredTransitions;
  }

  @visibleForTesting
  void addAncestorStatesToEnter(state, ancestor, statesToEnter,
      statesForDefaultEntry, defaultHistoryContent) {
    for (var anc in getProperAncestors(state, ancestor)) {
      statesToEnter.add(anc);
      if (anc.isParallel) {
        for (var child in getChildStates(anc)) {
          if (!statesToEnter.any((s) => isDescendant(s, child))) {
            addDescendantStatesToEnter(child, statesToEnter,
                statesForDefaultEntry, defaultHistoryContent);
          }
        }
      }
    }
  }

  @visibleForTesting
  void addDescendantStatesToEnter(
      state, statesToEnter, statesForDefaultEntry, defaultHistoryContent) {
    if (state.isHistoryState) {
      if (historyValues.containsKey(state.id)) {
        for (var s in historyValues[state.id]!) {
          addDescendantStatesToEnter(
              s, statesToEnter, statesForDefaultEntry, defaultHistoryContent);
        }
        for (var s in historyValues[state.id]!) {
          addAncestorStatesToEnter(s, state.parent, statesToEnter,
              statesForDefaultEntry, defaultHistoryContent);
        }
      } else {
        defaultHistoryContent[state.parent.id] = state.transition.content;
        for (var s in state.transition.target) {
          addDescendantStatesToEnter(
              s, statesToEnter, statesForDefaultEntry, defaultHistoryContent);
        }
        for (var s in state.transition.target) {
          addAncestorStatesToEnter(s, state.parent, statesToEnter,
              statesForDefaultEntry, defaultHistoryContent);
        }
      }
    } else {
      statesToEnter.add(state);
      if (state.isCompoundState) {
        statesForDefaultEntry.add(state);
        for (var s in state.initial.transition.target) {
          addDescendantStatesToEnter(
              s, statesToEnter, statesForDefaultEntry, defaultHistoryContent);
        }
        for (var s in state.initial.transition.target) {
          addAncestorStatesToEnter(s, state, statesToEnter,
              statesForDefaultEntry, defaultHistoryContent);
        }
      } else {
        if (state.isParallelState) {
          for (var child in getChildStates(state)) {
            if (!statesToEnter.any((s) => isDescendant(s, child))) {
              addDescendantStatesToEnter(child, statesToEnter,
                  statesForDefaultEntry, defaultHistoryContent);
            }
          }
        }
      }
    }
  }

  void computeEntrySet(Iterable<RuntimeTransition<T>> transitions) {
    for (var t in transitions) {
      for (var s in t.targetStates) {
        addDescendantStatesToEnter(
            s, _statesToEnter, _statesForDefaultEntry, _defaultHistoryContent);
      }
      final ancestor = getTransitionDomain(t);
      for (var s in getEffectiveTargetStates(t)) {
        addAncestorStatesToEnter(s, ancestor, _statesToEnter,
            _statesForDefaultEntry, _defaultHistoryContent);
      }
    }
  }

  Set<RuntimeState<T>> computeExitSet(transitions) {
    // ignore: prefer_collection_literals
    final statesToExit = LinkedHashSet<RuntimeState<T>>();
    for (var t in transitions) {
      if (t.target != null) {
        final domain = getTransitionDomain(t);
        for (var s in configuration) {
          if (isDescendant(s, domain!)) {
            statesToExit.add(s);
          }
        }
      }
    }
    return statesToExit;
  }

  @visibleForTesting
  RuntimeState<T> findLCCA(Iterable<RuntimeState<T>> stateList) =>
      getProperAncestors(stateList.first).where((s) => !s.isAtomic).firstWhere(
          (anc) => stateList.skip(1).every((s) => isDescendant(s, anc)));

  @visibleForTesting
  Iterable<RuntimeState<T>> getChildStates(RuntimeState<T> state) =>
      state.substates.where((s) => !s.isHistoryState);

  @visibleForTesting
  Iterable<RuntimeState<T>> getEffectiveTargetStates(transition) {
    // ignore: prefer_collection_literals
    final targets = LinkedHashSet<RuntimeState<T>>();
    for (var tid in transition.targets) {
      final s = tid.source;
      if (s.isHistoryState) {
        if (historyValues.containsKey(tid)) {
          targets.addAll(historyValues[tid]!);
        } else {
          targets.addAll(getEffectiveTargetStates(s.transition));
        }
      } else {
        targets.add(s!);
      }
    }
    return targets;
  }

  /// Finds the ancestors of a state
  ///
  /// If `toState` is null, returns the set of all ancestors of `fromState` up
  /// to (and including) `rootState`. If `toState` is not null, return all
  /// ancestors up to but not including `toState`.
  @visibleForTesting
  Iterable<RuntimeState<T>> getProperAncestors(RuntimeState<T> fromState,
      [RuntimeState<T>? toState]) sync* {
    if (fromState == root) return;
    if (toState != null && fromState == toState) return;
    var probe = fromState.parent;
    while (probe != null && toState != probe) {
      yield probe;
      if (probe == root) break;
      probe = probe.parent;
    }
  }

  @visibleForTesting
  RuntimeState<T>? getTransitionDomain(RuntimeTransition<T> t) {
    final tstates = getEffectiveTargetStates(t);
    if (tstates.isEmpty) return null;
    if (t.type == 'internal' &&
        t.source.isCompound &&
        tstates.every((s) => isDescendant(s, t.source))) {
      return t.source;
    }
    return findLCCA([t.source, ...tstates]);
  }

// The purpose of this procedure is to add to statesToEnter 'state' and any of its descendants that the state machine will end up entering when it enters 'state'. (N.B. If 'state' is a history pseudo-state, we dereference it and add the history value instead.) Note that this procedure permanently modifies both statesToEnter and statesForDefaultEntry.
//
// First, If state is a history state then add either the history values associated with state or state's default target to statesToEnter. Then (since the history value may not be an immediate descendant of 'state's parent) add any ancestors between the history value and state's parent. Else (if state is not a history state), add state to statesToEnter. Then if state is a compound state, add state to statesForDefaultEntry and recursively call addStatesToEnter on its default initial state(s). Then, since the default initial states may not be children of 'state', add any ancestors between the default initial states and 'state'. Otherwise, if state is a parallel state, recursively call addStatesToEnter on any of its child states that don't already have a descendant on statesToEnter.

  ///  True if state1 descends from state2
  @visibleForTesting
  bool isDescendant(RuntimeState<T> state1, RuntimeState<T> state2) =>
      getProperAncestors(state2).contains(state1);

// Add to statesToEnter any ancestors of 'state' up to, but not including, 'ancestor' that must be entered in order to enter 'state'. If any of these ancestor states is a parallel state, we must fill in its descendants as well.

  @visibleForTesting
  bool isInFinalState(State<T> s) => s.isCompound
      ? s.substates.any((c) => c.isFinal && configuration.contains(c))
      : s.isParallel
          ? s.substates.every((c) => isInFinalState(c))
          : false;
}
