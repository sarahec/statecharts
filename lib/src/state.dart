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
import 'package:quiver/collection.dart';
import 'package:quiver/core.dart';

// final _log = Logger('statecharts/State');

typedef Action<T> = void Function(T context);
typedef Condition<T> = bool Function(T context);

abstract class StateNode {
  final Symbol id;
  final Action? onEntry;
  final Action? onExit;

  const StateNode(this.id, this.onEntry, this.onExit);

  @override
  bool operator ==(Object other) =>
      other is StateNode &&
      id == other.id &&
      onEntry == other.onEntry &&
      onExit == other.onExit;

  @override
  int get hashCode => hash3(id, onEntry, onExit);
}

class State extends StateNode {
  final List<Transition>? transitions;

  final bool isInitial;
  final bool isTerminal;

  const State(id,
      {this.transitions,
      onEntry,
      onExit,
      this.isInitial = false,
      this.isTerminal = false})
      : super(id, onEntry, onExit);

  @override
  bool operator ==(Object other) =>
      other is State &&
      super == (other) &&
      listsEqual(transitions, other.transitions) &&
      isInitial == other.isInitial &&
      isTerminal == other.isTerminal;

  @override
  int get hashCode =>
      hashObjects([id, onEntry, onExit, transitions, isInitial, isTerminal]);
}

class StateMachine {
  final Symbol id;
  final Iterable<StateNode> states;

  State get initialState => states.firstWhere((s) => s is State && s.isInitial,
          orElse: () => throw AssertionError('initial state required for $id'))
      as State;

  const StateMachine(this.id, this.states);
}

class Statechart {
  final StateMachine container;

  const Statechart(this.container);
}

class Transition {
  final String? event;
  final Condition? condition;
  final Symbol targetId;

  final Action? action;

  const Transition(this.targetId, {this.event, this.condition, this.action})
      : assert(event != null || condition != null);
}
