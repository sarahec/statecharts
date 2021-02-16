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
import 'statechart.dart';

class Engine<T> {
  final StateMachine<T> container;

  final T? context;

  final ExecutionNode<T> rootNode;

  Engine(this.container, [this.context])
      : rootNode = ExecutionNode(container, context)..enterInitialState();

  State get currentState => rootNode.currentState;

  void execute(String event) {
    if (hasTransition(event)) {
      final transition = findTransition(event);
      executeTransition(transition);
    }
  }

  void executeTransition(Transition transition) {
    if (!transition.meetsCondition(context)) return;
    rootNode.currentState.exit(context);
    rootNode.executeTransition(transition);
    rootNode.currentState.enter(context);
  }

  Transition findTransition([String? event]) =>
      currentState.transitions.firstWhere(
          (Transition t) => t.canExecute(event: event, context: context));

  bool hasTransition([String? event]) => currentState.transitions
      .any((Transition t) => t.canExecute(event: event, context: context));
}

class ExecutionNode<T> {
  final StateMachine stateMachine;

  final T? context;

  // Iterable<ExecutionNode<T>> get children;

  var _currentState;
  ExecutionNode(this.stateMachine, this.context);

  State get currentState => _currentState;

  void enterInitialState() {
    _currentState = stateMachine.initialState;
    stateMachine.enter(context);
    _currentState.enter(context);
  }

  void executeTransition(Transition transition) =>
      _currentState = stateMachine.findState(transition.targetId);
}
