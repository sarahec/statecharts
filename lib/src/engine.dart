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
import 'package:statecharts/statecharts.dart';

class Engine<T> {
  final Statechart<T> statechart;
  final T? context;

  var _activeStates;

  final Map<String, StateNode<T>> _nodesByID;
  final Map<String, StateContainer<T>> _containerMap;

  Engine(this.statechart, [this.context])
      : _nodesByID = {for (var s in statechart.flatten) s.id: s},
        _containerMap = statechart.containerMap,
        _activeStates = statechart.initialStates;

  Iterable<ActiveState<T>> get activeStates => _activeStates;

  @protected
  set activeStates(Iterable<State> value) => _activeStates = value;

  Iterable<TransitionRecord<T>> nextActions(Iterable<State<T>> states,
      {String? anEvent, Duration? elapsedTime}) sync* {
    for (var s in states) {
      final t = s.transitionFor(
          event: anEvent, elapsedTime: elapsedTime, context: context);
      yield TransitionAction<T>(s, t);
      
      // The recursive bit gets a little tricky
    }
  }

  bool execute({String? anEvent, Duration? elapsedTime}) {
    assert(_activeStates.isNotEmpty);
    // Get the available transitions
    final startingState = _activeStates.first;
    final transition =
        startingState.transitionFor(event: anEvent, context: context);
    final endingState =
        statechart.find(id: transition.targetId, inChildren: false);
    if (endingState.id != startingState.id) {
      startingState.exit(context);
      endingState.enter(context);
      _activeStates[_activeStates.indexOf(startingState)] = endingState;
    }
    return endingState.id != startingState.id;
  }
}

class ActiveState<T> {
  final StateContainer<T> container;
  final State<T> state;

  ActiveState(this.container, this.state);
}

class TransitionRecord<T> {
  final ActiveState<T> active;
  final Transition<T> transition;

  TransitionRecord(this.state, this.transition)
}

extension InitialStates<T> on Statechart<T> {
  Iterable<ActiveState<T>> get initialStates sync* {
    yield* _initialStatesOf(this);
  }

  Iterable<ActiveState<T>> _initialStatesOf(StateContainer<T> container) sync* {
    if (container.children.isNotEmpty) {
      final child = container.children.firstWhere((s) => s.isInitial);
      yield ActiveState(container, child);
      if (child is StateContainer<T>) {
        yield* _initialStatesOf(child);
    }
  }
}

