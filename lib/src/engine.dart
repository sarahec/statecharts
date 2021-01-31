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
import '../statecharts.dart';

abstract class Engine {
  factory Engine(stateMachine) => StateMachineEngine(stateMachine);

  State get currentState;

  bool get isInitialState;

  bool canExecute(String event);

  void execute(String event);
}

class StateMachineEngine implements Engine {
  var _currentState;

  final StateMachine stateMachine;

  StateMachineEngine(this.stateMachine)
      : _currentState = stateMachine.initialState;

  @override
  State get currentState => _currentState;

  @override
  bool get isInitialState => _currentState == stateMachine.initialState;

  @override
  bool canExecute(String event) =>
      _currentState.transitions?.any((t) => t.event == event) ?? false;

  @override
  void execute(String event) {
    String? nextId = _currentState?.transitions
        ?.firstWhere((Transition t) => t.event == event)
        ?.targetId;
    if (nextId != null) {
      _currentState = stateMachine.findChild(nextId);
    }
  }
}
