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

class TransitionResolver<T> {
  /// The root of the tree (statechart).
  final RootState<T> root;
  final History<T> history;
  late final StateSet<T> activeStates,
      statesToEnter,
      statesForDefaultEntry,
      statesToExit;
  final defaultHistoryContent = <State<T>, Transition<T>>{};

  TransitionResolver(ExecutionStep<T> step)
      : root = step.tree.root,
        history = step.history {
    final tree = step.tree;
    activeStates = StateSet(root)..addAll(tree.activeStates);
    statesToEnter = StateSet(root);
    statesToExit = StateSet(root);
    statesForDefaultEntry = StateSet(root);
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

  void selectAncestors(State<T> state, StateTreeBuilder<T> b,
      [History? history]) {
    var probe = state;
    var parent = state.parent;
    while (parent != null) {
      b.linkParent(probe, parent);
      probe = parent;
      parent = probe.parent;
    }
  }

  void selectDescendents(State<T> state, StateTreeBuilder<T> b,
      [History? history]) {
    if (state.isAtomic) return;
    var probe = state;
    while (probe.isCompound) {
      if (probe.isParallel) {
        for (var s in probe.substates) {
          b.select(s, type: NodeType.defaultEntry);
          selectDescendents(s, b, history);
        }
        break;
      } else {
        final next =
            probe.initialTransition?.targetStates ?? [probe.substates.first];
        if (next.isEmpty) break;
        if (next.length > 1) {
          for (var s in next) {
            if (b.isSelected(s)) continue;
            b.select(s);
            selectAncestors(s, b, history);
            selectDescendents(s, b, history);
          }
          break;
        } else {
          final child = next.single;
          if (b.isSelected(child)) break;
          b.select(child, type: NodeType.defaultEntry);
          probe = child;
        }
      }
    }
  }

  /// enabledTransitions will contain multiple transitions only if a parallel state is active. In that case, we may have one transition selected for each of its children. These transitions may conflict with each other in the sense that they have incompatible target states. Loosely speaking, transitions are compatible when each one is contained within a single <state> child of the <parallel> element. Transitions that aren't contained within a single child force the state machine to leave the <parallel> ancestor (even if they reenter it later). Such transitions conflict with each other, and with transitions that remain within a single <state> child, in that they may have targets that cannot be simultaneously active. The test that transitions have non-intersecting exit sets captures this requirement. (If the intersection is null, the source and targets of the two transitions are contained in separate <state> descendants of <parallel>. If intersection is non-null, then at least one of the transitions is exiting the <parallel>). When such a conflict occurs, then if the source state of one of the transitions is a descendant of the source state of the other, we select the transition in the descendant. Otherwise we prefer the transition that was selected by the earlier state in document order and discard the other transition. Note that targetless transitions have empty exit sets and thus do not conflict with any other transitions.
  ///
  /// We start with a list of enabledTransitions and produce a conflict-free list of filteredTransitions. For each t1 in enabledTransitions, we test it against all t2 that are already selected in filteredTransitions. If there is a conflict, then if t1's source state is a descendant of t2's source state, we prefer t1 and say that it preempts t2 (so we we make a note to remove t2 from filteredTransitions). Otherwise, we prefer t2 since it was selected in an earlier state in document order, so we say that it preempts t1. (There's no need to do anything in this case since t2 is already in filteredTransitions. Furthermore, once one transition preempts t1, there is no need to test t1 against any other transitions.) Finally, if t1 isn't preempted by any transition in filteredTransitions, remove any transitions that it preempts and add it to that list.

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

/*
procedure microstep(enabledTransitions)
The purpose of the microstep procedure is to process a single set of transitions. These may have been enabled by an external event, an internal event, or by the presence or absence of certain values in the data model at the current point in time. The processing of the enabled transitions must be done in parallel ('lock step') in the sense that their source states must first be exited, then their actions must be executed, and finally their target states entered.

If a single atomic state is active, then enabledTransitions will contain only a single transition. If multiple states are active (i.e., we are in a parallel region), then there may be multiple transitions, one per active atomic state (though some states may not select a transition.) In this case, the transitions are taken in the document order of the atomic states that selected them.

procedure microstep(enabledTransitions):
    exitStates(enabledTransitions)
    executeTransitionContent(enabledTransitions)
    enterStates(enabledTransitions)

*/

/*
// procedure exitStates(enabledTransitions)
// Compute the set of states to exit. Then remove all the states on statesToExit from the set of states that will have invoke processing done at the start of the next macrostep. (Suppose macrostep M1 consists of microsteps m11 and m12. We may enter state s in m11 and exit it in m12. We will add s to statesToInvoke in m11, and must remove it in m12. In the subsequent macrostep M2, we will apply invoke processing to all states that were entered, and not exited, in M1.) Then convert statesToExit to a list and sort it in exitOrder.

// For each state s in the list, if s has a deep history state h, set the history value of h to be the list of all atomic descendants of s that are members in the current configuration, else set its value to be the list of all immediate children of s that are members of the current configuration. Again for each state s in the list, first execute any onexit handlers, then cancel any ongoing invocations, and finally remove s from the current configuration.

procedure exitStates(enabledTransitions):
    statesToExit = computeExitSet(enabledTransitions)           
    for s in statesToExit:
        statesToInvoke.delete(s)
    statesToExit = statesToExit.toList().sort(exitOrder)
    for s in statesToExit:
        for h in s.history:
            if h.type == "deep":
                f = lambda s0: isAtomicState(s0) and isDescendant(s0,s) 
            else:
                f = lambda s0: s0.parent == s
            historyValue[h.id] = configuration.toList().filter(f)
    for s in statesToExit:
        for content in s.onexit.sort(documentOrder):
            executeContent(content)
        for inv in s.invoke:
            cancelInvoke(inv)
        configuration.delete(s)
*/
  /// procedure computeExitSet(enabledTransitions)
  /// For each transition t in enabledTransitions, if t is targetless then do nothing, else compute the transition's domain. (This will be the source state in the case of internal transitions) or the least common compound ancestor state of the source state and target states of t (in the case of external transitions. Add to the statesToExit set all states in the configuration that are descendants of the domain.
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

/*   
procedure executeTransitionContent(enabledTransitions)
For each transition in the list of enabledTransitions, execute its executable content.

procedure executeTransitionContent(enabledTransitions):
    for t in enabledTransitions:
        executeContent(t)
procedure enterStates(enabledTransitions)
First, compute the list of all the states that will be entered as a result of taking the transitions in enabledTransitions. Add them to statesToInvoke so that invoke processing can be done at the start of the next macrostep. Convert statesToEnter to a list and sort it in entryOrder. For each state s in the list, first add s to the current configuration. Then if we are using late binding, and this is the first time we have entered s, initialize its data model. Then execute any onentry handlers. If s's initial state is being entered by default, execute any executable content in the initial transition. If a history state in s was the target of a transition, and s has not been entered before, execute the content inside the history state's default transition. Finally, if s is a final state, generate relevant Done events. If we have reached a top-level final state, set running to false as a signal to stop processing.

procedure enterStates(enabledTransitions):
    statesToEnter = new OrderedSet()
    statesForDefaultEntry = new OrderedSet()
    // initialize the temporary table for default content in history states
    defaultHistoryContent = new HashTable() 
    computeEntrySet(enabledTransitions, statesToEnter, statesForDefaultEntry, defaultHistoryContent) 
    for s in statesToEnter.toList().sort(entryOrder):
        configuration.add(s)
        statesToInvoke.add(s)
        if binding == "late" and s.isFirstEntry:
            initializeDataModel(datamodel.s,doc.s)
            s.isFirstEntry = false
        for content in s.onentry.sort(documentOrder):
            executeContent(content)
        if statesForDefaultEntry.isMember(s):
            executeContent(s.initial.transition)
        if defaultHistoryContent[s.id]:
            executeContent(defaultHistoryContent[s.id]) 
        if isFinalState(s):
            if isSCXMLElement(s.parent):
                running = false
            else:
                parent = s.parent
                grandparent = parent.parent
                internalQueue.enqueue(new Event("done.state." + parent.id, s.donedata))
                if isParallelState(grandparent):
                    if getChildStates(grandparent).every(isInFinalState):
                        internalQueue.enqueue(new Event("done.state." + grandparent.id))
 
 */

// procedure computeEntrySet(transitions, statesToEnter, statesForDefaultEntry, defaultHistoryContent)
// Compute the complete set of states that will be entered as a result of taking 'transitions'. This value will be returned in 'statesToEnter' (which is modified by this procedure). Also place in 'statesForDefaultEntry' the set of all states whose default initial states were entered. First gather up all the target states in 'transitions'. Then add them and, for all that are not atomic states, add all of their (default) descendants until we reach one or more atomic states. Then add any ancestors that will be entered within the domain of the transition. (Ancestors outside of the domain of the transition will not have been exited.)

  void computeEntrySet(transitions) {
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

// procedure addDescendantStatesToEnter(state,statesToEnter,statesForDefaultEntry, defaultHistoryContent)
// The purpose of this procedure is to add to statesToEnter 'state' and any of its descendants that the state machine will end up entering when it enters 'state'. (N.B. If 'state' is a history pseudo-state, we dereference it and add the history value instead.) Note that this procedure permanently modifies both statesToEnter and statesForDefaultEntry.

// First, If state is a history state then add either the history values associated with state or state's default target to statesToEnter. Then (since the history value may not be an immediate descendant of 'state's parent) add any ancestors between the history value and state's parent. Else (if state is not a history state), add state to statesToEnter. Then if state is a compound state, add state to statesForDefaultEntry and recursively call addStatesToEnter on its default initial state(s). Then, since the default initial states may not be children of 'state', add any ancestors between the default initial states and 'state'. Otherwise, if state is a parallel state, recursively call addStatesToEnter on any of its child states that don't already have a descendant on statesToEnter.

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
    } else {
      statesToEnter.add(state);
      if (state.isCompound) {
        statesForDefaultEntry.add(state);
        for (var s in state.initialStates) {
          addDescendantStatesToEnter(s);
          addAncestorStatesToEnter(s, state);
        }
      } else if (state.isParallel) {
        for (var child in state.substates) {
          if (!statesToEnter.any((s) => s.descendsFrom(child))) {
            addDescendantStatesToEnter(child);
          }
        }
      }
    }
  }
// procedure addAncestorStatesToEnter(state, ancestor, statesToEnter, statesForDefaultEntry, defaultHistoryContent)
// Add to statesToEnter any ancestors of 'state' up to, but not including, 'ancestor' that must be entered in order to enter 'state'. If any of these ancestor states is a parallel state, we must fill in its descendants as well.

  void addAncestorStatesToEnter(State<T> state, State<T>? ancestor) {
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
// procedure isInFinalState(s)
// Return true if s is a compound <state> and one of its children is an active <final> state (i.e. is a member of the current configuration), or if s is a <parallel> state and isInFinalState is true of all its children.

  bool isInFinalState(State<T> s) => s.isCompound
      ? s.substates.any((s) => s.isFinal && activeStates.contains(s))
      : s.isParallel
          ? s.substates.every((s) => isInFinalState(s))
          : false;
}
