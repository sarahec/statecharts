/**
 * Copyright 2021 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import 'dart:collection';

import 'package:meta/meta.dart';
import 'package:statecharts/statecharts.dart';

class Engine<T> {
  final RuntimeState<T> root;
  final T? context;

  Iterable<RuntimeState<T>> _configuration = {};

  var _statesToInvoke;
  var _datamodel;
  var _internalQueue;
  var _externalQueue;
  var _historyValue;
  var _running;
  var _binding;
  var _savedHistoryStates;

  Engine(RootState<T> startNode, [this.context])
      : root = RuntimeState.wrapSubtree(startNode);

  Iterable<State<T>> get activeStates => _configuration.map((i) => i.state);

  bool execute({String? anEvent, Duration? elapsedTime}) {
    // assert(_activeStates.isNotEmpty);
    throw UnimplementedError();
    // // Get the available transitions
    // final startingState = _activeStates.first;
    // final transition =
    //     startingState.transitionFor(event: anEvent, context: context);
    // final endingState =
    //     statechart.find(id: transition.targetId, inChildren: false);
    // if (endingState.id != startingState.id) {
    //   startingState.exit(context);
    //   endingState.enter(context);
    //   _activeStates[_activeStates.indexOf(startingState)] = endingState;
    // }
    // return endingState.id != startingState.id;
  }

  RuntimeState<T> findLCCA(Iterable<RuntimeState<T>> stateList) =>
      getProperAncestors(stateList.first).where((s) => !s.isAtomic).firstWhere(
          (anc) => stateList.skip(1).every((s) => isDescendant(s, anc)));

  Iterable<RuntimeState<T>> getChildStates(RuntimeState<T> state) =>
      state.substates.where((s) => !s.isHistoryState);

  @visibleForTesting
  Iterable<RuntimeState<T>> getEffectiveTargetStates(transition) {
    // ignore: prefer_collection_literals
    final targets = LinkedHashSet<RuntimeState<T>>();
    for (var tid in transition.targets) {
      final s = tid.source;
      if (s.isHistoryState) {
        if (_savedHistoryStates.hasKey(tid)) {
          targets.addAll(_savedHistoryStates[tid]);
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
  State<T>? getTransitionDomain(RuntimeTransition<T> t) {
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
  bool isDescendant(RuntimeState<T> state1, RuntimeState<T> state2) =>
      getProperAncestors(state2).contains(state1);

  bool isInFinalState(State<T> s) => s.isCompound
      ? s.substates.any((c) => c.isFinal && _configuration.contains(c))
      : s.isParallel
          ? s.substates.every((c) => isInFinalState(c))
          : false;
}
