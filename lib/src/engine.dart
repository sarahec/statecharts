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

  final ExecutionNode<T> rootNode;

  Engine(this.container, [this.context])
      : rootNode = ExecutionNode(container)..enterInitialState(context);

  Iterable<State> get activeStates => [rootNode.currentState];

  State get currentState => rootNode.currentState;

  void execute({String? anEvent, Duration? elapsedTime}) {
    if (rootNode.hasTransition(event: anEvent, elapsedTime: elapsedTime)) {
      final transition =
          rootNode.findTransition(event: anEvent, elapsedTime: elapsedTime);
      executeTransition(transition);
    }
  }

  void executeTransition(Transition transition) {
    if (!transition.meetsCondition(context)) return;
    rootNode.currentState.exit(context);
    rootNode.executeTransition(transition);
    rootNode.currentState.enter(context);
  }
}

class ExecutionNode<T> {
  final Statechart container;

  var _currentState;
  ExecutionNode(this.container);

  State get currentState => _currentState;

  void enterInitialState(T? context) {
    _currentState = container.initialState;
    container.enter(context);
    _currentState.enter(context);
  }

  void executeTransition(Transition transition) =>
      _currentState = container.stateNamed(transition.targetId);

  Transition findTransition({String? event, Duration? elapsedTime}) =>
      currentState.transitions.firstWhere((Transition t) =>
          t.matches(anEvent: event, elapsedTime: elapsedTime));

  bool hasTransition({String? event, Duration? elapsedTime}) =>
      currentState.transitions.any((Transition t) =>
          t.matches(anEvent: event, elapsedTime: elapsedTime));
}
