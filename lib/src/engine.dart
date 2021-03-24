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
  final Statechart<T> container;
  final T? context;

  Iterable<State> get activeStates => _activeStates;

  var _activeStates = <State>[];

  factory Engine(Statechart<T> container, [T? context]) =>
      Engine._(container, context, [container.initialState]);

  bool execute({String? anEvent, Duration? elapsedTime}) {
    assert(_activeStates.isNotEmpty);
    // Get the available transitions
    final startingState = _activeStates.first;
    final transition =
        startingState.transitionFor(event: anEvent!, context: context);
    final endingState =
        container.findState(id: transition.targetId, inChildren: false);
    if (endingState.id != startingState.id) {
      startingState.exit(context);
      endingState.enter(context);
      _activeStates[_activeStates.indexOf(startingState)] = endingState;
    }
    return endingState.id != startingState.id;
  }

  Engine._(this.container, this.context, this._activeStates);
}

class ExecutionState {}

class ActiveStateRecord<T> {
  final StateContainer<T> container;
  final State<T> activeState;

  ActiveStateRecord(this.container, this.activeState);

  ActiveStateRecord withNewState(State<T> newState) =>
      ActiveStateRecord<T>(container, newState);
}
