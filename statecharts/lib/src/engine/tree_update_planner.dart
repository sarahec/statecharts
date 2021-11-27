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

class TreeUpdatePlanner<T> {
  /// The root of the tree (statechart).
  final RootState<T> root;
  final History<T> history;
  final StateSet<T> activeStates,
      statesToEnter,
      statesForDefaultEntry,
      statesToExit;
  final defaultHistoryContent = <State<T>, Transition<T>>{};

  TreeUpdatePlanner(RootState<T> root,
      {History<T>? history, Iterable<State<T>> priorStates = const []})
      // ignore: prefer_initializing_formals
      : root = root,
        history = history ?? History(root),
        activeStates = StateSet(root)..addAll(priorStates),
        statesToEnter = StateSet(root),
        statesToExit = StateSet(root),
        statesForDefaultEntry = StateSet(root);

  /// Add to statesToEnter any ancestors of 'state' up to, but not including,
  /// 'ancestor' that must be entered in order to enter 'state'. If any of
  /// these ancestor states is a parallel state, we must fill in its
  /// descendants as well.
  void addAncestorStatesToEnter(State<T> state, [State<T>? ancestor]) {
    for (var anc in state.ancestors(upTo: ancestor)) {
      statesToEnter.add(anc);
      if (anc.isParallel) {
        for (var child in anc.substates) {
          if (!statesToEnter.any((s) => s.descendsFrom(child))) {
            addDescendantStatesToEnter(child);
          }
        }
      }
    }
  }

  /// The purpose of this procedure is to add to statesToEnter 'state' and any
  /// of its descendants that the state machine will end up entering when it
  /// enters 'state'. (N.B. If 'state' is a history pseudo-state, we
  /// dereference it and add the history value instead.) Note that this
  /// procedure permanently modifies both statesToEnter and statesForDefaultEntry.
  ///
  /// First, If state is a history state then add either the history values
  /// associated with state or state's default target to statesToEnter.
  /// Then (since the history value may not be an immediate descendant of
  /// 'state's parent) add any ancestors between the history value and state's
  /// parent. Else (if state is not a history state), add state to
  /// statesToEnter. Then if state is a compound state, add state to
  /// statesForDefaultEntry and recursively call addStatesToEnter on its
  /// default initial state(s). Then, since the default initial states may not
  /// be children of 'state', add any ancestors between the default initial
  /// states and 'state'. Otherwise, if state is a parallel state, recursively
  /// call addStatesToEnter on any of its child states that don't already have
  /// a descendant on statesToEnter.
  void addDescendantStatesToEnter(State<T> state) {
    if (state is HistoryState<T>) {
      if (history.contains(state)) {
        final historyValue = history[state]!;
        for (var s in historyValue) {
          addDescendantStatesToEnter(s);
        }
        for (var s in historyValue) {
          addAncestorStatesToEnter(s, state.parent);
        }
      } else {
        defaultHistoryContent[state.parent!] = state.transition;
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
    statesToEnter.add(state);
    if (state.isParallel) {
      for (var child in state.substates) {
        if (!statesToEnter.any((s) => s.descendsFrom(child))) {
          addDescendantStatesToEnter(child);
        }
      }
    } else if (state.isCompound) {
      statesForDefaultEntry.add(state);
      for (var s in state.initialStates) {
        addDescendantStatesToEnter(s);
        addAncestorStatesToEnter(s, state);
      }
    }
  }

  /// Compute the complete set of states that will be entered as a result of
  /// taking 'transitions'. This value will be returned in 'statesToEnter'
  /// (which is modified by this procedure). Also place in
  /// 'statesForDefaultEntry' the set of all states whose default initial
  ///  states were entered. First gather up all the target states in
  /// 'transitions'. Then add them and, for all that are not atomic states,
  /// add all of their (default) descendants until we reach one or more atomic
  /// states. Then add any ancestors that will be entered within the domain of
  /// the transition. (Ancestors outside of the domain of the transition will
  /// not have been exited.)
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

  /// For each transition t in enabledTransitions, if t is targetless then do
  /// nothing, else compute the transition's domain. (This will be the source
  /// state in the case of internal transitions) or the least common compound
  /// ancestor state of the source state and target states of t (in the case
  /// of external transitions. Add to the statesToExit set all states in the
  /// configuration that are descendants of the domain.
  StateSet<T> computeExitSet(Iterable<Transition<T>> transitions) {
    final statesToExit = StateSet(root);
    for (var t in transitions.where((t) => t.targetStates.isNotEmpty)) {
      final domain = getTransitionDomain(t)!;
      for (var s in activeStates) {
        if (s.descendsFrom(domain)) {
          statesToExit.add(s);
        }
      }
    }
    return statesToExit;
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

  /// Return true if s is a compound <state> and one of its children is an
  /// active <final> state (i.e. is a member of the current configuration), or
  /// if s is a <parallel> state and isInFinalState is true of all its children.
  bool isInFinalState(State<T> s) => s.isCompound
      ? s.substates.any((s) => s.isFinal && activeStates.contains(s))
      : s.isParallel
          ? s.substates.every((s) => isInFinalState(s))
          : false;

  /// enabledTransitions will contain multiple transitions only if a parallel
  /// state is active. In that case, we may have one transition selected for
  /// each of its children. These transitions may conflict with each other in
  /// the sense that they have incompatible target states. Loosely speaking,
  /// transitions are compatible when each one is contained within a single
  /// <state> child of the <parallel> element. Transitions that aren't
  /// contained within a single child force the state machine to leave the
  /// <parallel> ancestor (even if they reenter it later). Such transitions
  /// conflict with each other, and with transitions that remain within a
  /// single <state> child, in that they may have targets that cannot be
  /// simultaneously active. The test that transitions have non-intersecting
  /// exit sets captures this requirement. (If the intersection is null, the
  /// source and targets of the two transitions are contained in separate
  /// <state> descendants of <parallel>. If intersection is non-null, then at
  /// least one of the transitions is exiting the <parallel>). When such a
  /// conflict occurs, then if the source state of one of the transitions is a
  /// descendant of the source state of the other, we select the transition in
  /// the descendant. Otherwise we prefer the transition that was selected by
  /// the earlier state in document order and discard the other transition.
  /// Note that targetless transitions have empty exit sets and thus do not
  /// conflict with any other transitions.
  ///
  /// We start with a list of enabledTransitions and produce a conflict-free
  /// list of filteredTransitions. For each t1 in enabledTransitions, we test
  /// it against all t2 that are already selected in filteredTransitions. If
  /// there is a conflict, then if t1's source state is a descendant of t2's
  /// source state, we prefer t1 and say that it preempts t2 (so we we make a
  /// note to remove t2 from filteredTransitions). Otherwise, we prefer t2
  /// since it was selected in an earlier state in document order, so we say
  /// that it preempts t1. (There's no need to do anything in this case since
  /// t2 is already in filteredTransitions. Furthermore, once one transition
  /// preempts t1, there is no need to test t1 against any other transitions.)
  ///  Finally, if t1 isn't preempted by any transition in filteredTransitions,
  ///  remove any transitions that it preempts and add it to that list.
  Iterable<Transition<T>> removeConflictingTransitions(
      Iterable<Transition<T>> enabledTransitions) {
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
}
