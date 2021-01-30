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

class State implements StateNode {
  @override
  final Symbol id;
  final bool isInitial;
  final bool isTerminal;
  @override
  final Action? onEntry;
  @override
  final Action? onExit;
  final List<Transition>? transitions;

  const State(this.id,
      {this.transitions,
      this.onEntry,
      this.onExit,
      this.isInitial = false,
      this.isTerminal = false});

  @override
  int get hashCode =>
      hashObjects([id, onEntry, onExit, transitions, isInitial, isTerminal]);
  @override
  bool operator ==(Object other) =>
      other is State &&
      id == other.id &&
      onEntry == other.onEntry &&
      onExit == other.onExit &&
      listsEqual(transitions, other.transitions) &&
      isInitial == other.isInitial &&
      isTerminal == other.isTerminal;
}

class Statechart implements StateContainer {
  @override
  final Symbol id;
  @override
  final Action? onEntry;
  @override
  final Action? onExit;
  final StateMachine container;

  const Statechart(this.id, this.container, {this.onEntry, this.onExit});
}

class StateMachine implements StateContainer {
  @override
  final Symbol id;
  @override
  final Action? onEntry;
  @override
  final Action? onExit;
  final Iterable<StateNode> states;

  const StateMachine(this.id, this.states, {this.onEntry, this.onExit});

  State get initialState => states.firstWhere((s) => s is State && s.isInitial,
          orElse: () => throw AssertionError('initial state required for $id'))
      as State;
}

abstract class StateNode {
  Symbol get id;
  Action? get onEntry;
  Action? get onExit;
}

abstract class StateContainer extends StateNode {}

class Transition {
  final String? event;
  final Condition? condition;
  final Symbol targetId;

  final Action? action;

  const Transition(this.targetId, {this.event, this.condition, this.action})
      : assert(event != null || condition != null);
}
