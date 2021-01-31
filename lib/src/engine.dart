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

abstract class Engine<T> {
  factory Engine(stateMachine, [context]) =>
      StateMachineEngine<T>(stateMachine, context);

  T? get context;

  State get currentState;

  void enterInitialState();

  void execute(String event);

  bool hasTransition(String event);
}

class StateMachineEngine<T> implements Engine<T> {
  var _currentState;

  final T? context;

  final StateMachine<T> stateMachine;

  StateMachineEngine(this.stateMachine, [this.context]);

  @override
  State get currentState => _currentState!;

  @override
  void enterInitialState() {
    final initialState = stateMachine.initialState;
    _currentState = initialState;
    stateMachine.enter(context);
    initialState.enter(context);
  }

  @override
  void execute([String? event]) {
    if (_currentState == null) enterInitialState();
    if (hasTransition(event)) {
      final transition = findTransition(event);
      executeTransition(transition);
    }
  }

  void executeTransition(Transition<T> transition) {
    if (transition.meetsCondition(context)) {
      _currentState.exit(context);
      _currentState = stateMachine.findChild(transition.targetId);
      _currentState.enter(context);
    }
  }

  @override
  bool hasTransition([String? event]) =>
      _currentState.transitions?.any(
          (Transition<T> t) => t.canExecute(event: event, context: context)) ??
      false;

  Transition<T> findTransition([String? event]) =>
      _currentState?.transitions?.firstWhere(
          (Transition<T> t) => t.canExecute(event: event, context: context));
}
