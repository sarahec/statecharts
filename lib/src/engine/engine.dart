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
import 'package:meta/meta.dart';
import 'package:statecharts/statecharts.dart';

class Engine<T> {
  final State<T> rootState;
  final T? context;
  final Map<State<T>, State<T>> _parentOf = {};
  final Map<String, State<T>> _nodeLookup = {};
  var _activeStates;

  Engine(this.rootState, [this.context])
      : _activeStates = rootState.initialStates;

  State<T>? nodeById(String id) {
    void addChildren(container) {
      if (!container.isAtomic) {
        _nodeLookup
            .addAll({for (var child in container.substates) child: container});
        for (var child in container.substates) {
          addChildren(child);
        }
      }
    }

    if (_nodeLookup.isEmpty) {
      addChildren(rootState);
    }
    return _nodeLookup[id];
  }

  State<T>? parentOf(State<T> state) {
    void addChildren(container) {
      if (!container.isAtomic) {
        _parentOf
            .addAll({for (var child in container.substates) child: container});
        for (var child in container.substates) {
          addChildren(child);
        }
      }
    }

    if (_parentOf.isEmpty) {
      addChildren(rootState);
    }
    return _parentOf[state];
  }

  /// Finds the ancestors of a state
  ///
  /// If `toState` is null, returns the set of all ancestors of `fromState` up
  /// to (and including) `rootState`. If `toState` is not null, return all
  /// ancestors up to but not including `toState`.
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

  ///  True if state1 descends from state2
  bool isDescendant(state1, state2) =>
      getProperAncestors(state2).contains(state1);

  Iterable<State<T>> get activeStates => _activeStates;

  Iterable<State<T>> getChildStates(state) =>
      state.substates.where((s) => !s is HistoryState);

  @protected
  set activeStates(Iterable<State> value) => _activeStates = value;

  // Iterable<State<T>> get initialStates =>
  //     findAll(rootState, (s) => s.isInitial);

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
}
