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
  final State<T> rootState;
  final T? context;
  final Map<State<T>, State<T>?> _parentOf;
  // Use a LinkedHashMap to preserve document order
  final LinkedHashMap<String, State<T>> _nodeLookup;
  var _activeStates;

  Iterable<State<T>> _configuration = {};
  var _statesToInvoke;
  var _datamodel;
  var _internalQueue;
  var _externalQueue;
  var _historyValue;
  var _running;
  var _binding;

  var _savedHistoryStates;

  Engine(this.rootState, [this.context])
      : _activeStates = rootState.initialStates,
        _nodeLookup = LinkedHashMap.fromIterable(
            rootState.flatten.where((s) => s.id != null),
            key: (s) => s.id,
            value: (s) => s),
        _parentOf = Map.fromEntries(parentEntries(rootState));

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

  @visibleForTesting
  State<T> findLCCA(stateList) => getProperAncestors(stateList.first)
      .where((s) => !s.isAtomic)
      .firstWhere((anc) => stateList.skip(1).all((s) => isDescendant(s, anc)));

  @visibleForTesting
  Iterable<State<T>> getChildStates(state) =>
      state.substates.where((s) => !s is HistoryState);

  @visibleForTesting
  Iterable<State<T>> getEffectiveTargetStates(transition) {
    // ignore: prefer_collection_literals
    final targets = LinkedHashSet<State<T>>();
    for (var tid in transition.targets) {
      final s = nodeById(tid);
      if (s is HistoryState<T>) {
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
  @visibleForTesting
  Iterable<State<T>> getProperAncestors(fromState, [toState]) sync* {
    if (fromState == rootState) return;
    if (toState != null && fromState == toState) return;
    var probe = parentOf(fromState);
    while (probe != null && toState != probe) {
      yield probe;
      if (probe == rootState) break;
      probe = parentOf(probe);
    }
  }

  @visibleForTesting
  State<T>? getTransitionDomain(TransitionRecord<T> t) {
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
  bool isDescendant(state1, state2) =>
      getProperAncestors(state2).contains(state1);

  bool isInFinalState(State<T> s) => s.isCompound
      ? s.substates.any((c) => c.isFinal && _configuration.contains(c))
      : s.isParallel
          ? s.substates.every((c) => isInFinalState(c))
          : false;

  @visibleForTesting
  State<T>? nodeById(String id) => _nodeLookup[id];

  @visibleForTesting
  State<T>? parentOf(State<T> state) => _parentOf[state];

  @visibleForTesting
  static Iterable<MapEntry<State<T>, State<T>?>> parentEntries<T>(
      State<T> state,
      [State<T>? parent]) sync* {
    yield MapEntry(state, parent);
    for (var child in state.substates) {
      yield* parentEntries(child, state);
    }
  }
}

class TransitionRecord<T> {
  final State<T> source;
  final Transition<T> transition;

  TransitionRecord(this.source, this.transition);

  String get type => transition.type;
}
