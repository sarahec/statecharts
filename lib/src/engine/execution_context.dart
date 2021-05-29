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
// See the License for the specific language goveRuntimeState<T>ning permissions and
// limitations under the License.

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:ordered_set/comparing.dart';
import 'package:ordered_set/ordered_set.dart';
import 'package:statecharts/statecharts.dart';

class ExecutionContext<T> {
  final RuntimeState<T> root;
  @visibleForTesting
  final historyValues = <String, Iterable<RuntimeState<T>>>{};
  // final _configuration;

  final _lookupMap = <String, RuntimeState<T>>{};

  @Deprecated('use local')
  final defaultHistoryContent = 0;

  var _statesToEnter;

  /// Load the root node and, optionally, configure the active nodes
  @visibleForTesting
  factory ExecutionContext.forTest(RootState<T> rootNode,
          {Iterable<String>? activeIDs}) =>
      ExecutionContext._(RuntimeState.wrapSubtree(rootNode)).._buildLookupMap();

  factory ExecutionContext.initial(RootState<T> rootNode) =>
      ExecutionContext._(RuntimeState.wrapSubtree(rootNode))
        .._buildLookupMap()
        ..selectInitialStates(rootNode.initializingTransitions);

  ExecutionContext._(this.root);

  @visibleForTesting
  Iterable<RuntimeState<T>> get statesForDefaultEntry => _statesToEnter;

  /// Shorthand for [findState]
  @visibleForTesting
  RuntimeState<T>? operator [](String? id) => findState(id);

  @visibleForTesting
  void addAncestorStatesToEnter(
      RuntimeState<T> state, RuntimeState<T>? ancestor) {
    for (var anc in state.ancestors(upTo: ancestor)) {
      _statesToEnter.add(anc);
      if (anc.isParallel) {
        for (var child in getChildStates(anc)) {
          if (!_statesToEnter.any((s) => isDescendant(s, child))) {
            addDescendantStatesToEnter(child);
          }
        }
      }
    }
  }

  @visibleForTesting
  void addDescendantStatesToEnter(RuntimeState<T>? state) {
    if (state == null) return;
    if (state.isHistoryState) {
      if (historyValues.containsKey(state.id)) {
        for (var s in historyValues[state.id]!) {
          addDescendantStatesToEnter(s);
        }
        for (var s in historyValues[state.id]!) {
          addAncestorStatesToEnter(s, state.parent);
        }
      } else {
        // state.transition.content contains the executable elements for the transition
        _defaultHistoryContent[state.parent?.id] = state.transition.content;
        for (var s in state.transition.target) {
          addDescendantStatesToEnter(s);
        }
        for (var s in state.transition.target) {
          addAncestorStatesToEnter(s, state.parent);
        }
      }
    } else {
      _statesToEnter.add(state);
      if (state.isCompound) {
        _statesForDefaultEntry.add(state);
        for (var s in state.initialSubstates) {
          addDescendantStatesToEnter(s);
        }
        for (var s in state.initialSubstates) {
          addAncestorStatesToEnter(s, state);
        }
      } else {
        if (state.isParallel) {
          for (var child in getChildStates(state)) {
            if (!_statesToEnter.any((s) => isDescendant(s, child))) {
              addDescendantStatesToEnter(child);
            }
          }
        }
      }
    }
  }

  void computeEntrySet(Iterable<RuntimeTransition<T>> transitions) {
    /*
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
    */
  }

  Set<RuntimeState<T>> computeExitSet(transitions, activeStates) {
    final statesToExit = <RuntimeState<T>>{};
    for (var t in transitions.where((probe) => probe.target != null)) {
      final domain = getTransitionDomain(t)!;
      statesToExit.addAll(activeStates.where((s) => isDescendant(s, domain)));
    }
    return statesToExit;
  }

  @visibleForTesting
  int documentOrder(a, b) => a.order.compareTo(b.order);

  /// Finds the lowest common compound ancestor of multiple states.
  ///
  /// This finds the minimal subtree contaning a set of states.
  @visibleForTesting
  RuntimeState<T> findLCCA(Iterable<RuntimeState<T>> stateList) => stateList
      .map((s) => Set.of(s.ancestors()))
      .reduce((a, b) => a.intersection(b))
      .where((s) => s.isCompound)
      .reduce((a, b) => a.order >= b.order ? a : b);

  RuntimeState<T>? findState(String? id) => id == null ? null : _lookupMap[id];

  RuntimeTransition<T>? findTransition(String toState, {String? inside}) =>
      (findState(inside) ??
              root.toIterable.firstWhereOrNull((s) => s.hasTransition(toState)))
          ?.getTransition(toState);

  @visibleForTesting
  Iterable<RuntimeState<T>> getChildStates(RuntimeState<T> state) =>
      state.substates.where((s) => !s.isHistoryState);

  @visibleForTesting

  /// Used in: [computeEntrySet] and [getTransitionDomain]
  Iterable<RuntimeState<T>> getEffectiveTargetStates(
      RuntimeTransition<T> transition) {
    Iterable<RuntimeState<T>> _getEffectiveTargetStates(
        RuntimeTransition<T> transition) sync* {
      for (var s in transition.targetStates) {
        if (!s.isHistoryState) {
          yield s;
        } else {
          if (historyValues.containsKey(s.id)) {
            for (var historyState in historyValues[s.id]!) {
              yield historyState;
            }
          } else {
            for (var t in s.transitions) {
              yield* _getEffectiveTargetStates(t);
            }
          }
        }
      }
    }

    return OrderedSet(Comparing.on((p) => p.order))
      ..addAll(_getEffectiveTargetStates(transition));
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

  ///  True if state1 descends from state2
  @visibleForTesting
  bool isDescendant(RuntimeState<T> state1, RuntimeState<T> state2) =>
      state1.ancestors().contains(state2);

  @visibleForTesting
  bool isInFinalState(State<T> s, activeStates) => s.isParallel
      ? s.substates.every((c) => isInFinalState(c, activeStates))
      : s.isCompound
          ? s.substates.any((c) => c.isFinal && activeStates.contains(c))
          : s.isFinal && activeStates.contains(s);

  Iterable<RuntimeTransition<T>> selectTransitions(
      String? event, T? context, Iterable<RuntimeState<T>> activeStates) {
    var enabledTransitions =
        OrderedSet<RuntimeTransition<T>>(Comparing.on((t) => t.source.order));
    for (var state in activeStates.where((s) => s.isAtomic)) {
      for (var s in [state, ...state.ancestors()]) {
        for (var t in s.transitions) {
          // n.b. assumes sorting in document order for transitions
          if (t.matches(anEvent: event, context: context)) {
            enabledTransitions.add(t);
            break;
          }
        }
      }
    }
    return _removeConflictingTransitions(enabledTransitions, activeStates);
  }

  Iterable<RuntimeTransition<T>> _removeConflictingTransitions(
      Iterable<RuntimeTransition<T>> enabledTransitions,
      Iterable<RuntimeState<T>> activeStates) {
    final filteredTransitions =
        OrderedSet<RuntimeTransition<T>>(Comparing.on((t) => t.source.order));
    for (var t1 in enabledTransitions) {
      var t1Preempted = false;
      final transitionsToRemove = <RuntimeTransition<T>>{};
      for (var t2 in filteredTransitions) {
        if (computeExitSet([t1], activeStates)
            .intersection(computeExitSet([t2], activeStates))
            .isNotEmpty) {
          if (isDescendant(t1.source, t2.source)) {
            transitionsToRemove.add(t2);
          } else {
            t1Preempted = true; // t2 overrides t1
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
  } // spec returns false here

  void _buildLookupMap() {
    assert(_lookupMap.isEmpty); // should only be called once
    root.toIterable
        .where((s) => s.id != null)
        .forEach((state) => _lookupMap[state.id!] = state);
  }

  void selectInitialStates(Iterable<Transition<T>> transitions) {
    final runtimeTransitions = [
      for (var t in transitions)
        RuntimeTransition<T>(t, root)..attachTargetStates(_lookupMap)
    ];
    computeEntrySet(runtimeTransitions);
  }

  Iterable<RuntimeState<T>> selectStates([Iterable<String>? ids]) => ids == null
      ? []
      : (OrderedSet<RuntimeState<T>>(Comparing.on((s) => s.order))
        ..addAll(ids.map((id) => _lookupMap[id]!)));
}
