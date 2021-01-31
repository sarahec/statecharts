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
  final String id;
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
  Set<String> get events => transitions == null
      ? {}
      : {for (var t in transitions!.where((t) => t.event != null)) t.event!};

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

  bool hasTransitionFor({required String event}) => events.contains(event);

  Transition transitionFor({required String event}) =>
      transitions!.firstWhere((t) => t.event == event);
}

class Statechart implements StateContainer {
  @override
  final String id;
  @override
  final Action? onEntry;
  @override
  final Action? onExit;
  final StateMachine stateMachine;

  const Statechart(this.id, this.stateMachine, {this.onEntry, this.onExit});

  @override
  Set<String> get events => stateMachine.events;

  @override
  State get initialState => stateMachine.initialState;

  @override
  Set<String> get paths =>
      {for (var event in stateMachine.events) '$id.$event'};
}

abstract class StateContainer extends StateNode {
  State get initialState;
  Set<String> get paths;
}

class StateMachine implements StateContainer {
  @override
  final String id;
  @override
  final Action? onEntry;
  @override
  final Action? onExit;
  final Iterable<State> states;

  const StateMachine(this.id, this.states, {this.onEntry, this.onExit});

  @override
  Set<String> get events {
    final result = <String>{};

    for (var s in states) {
      result.addAll(s.events);
    }
    return result;
  }

  @override
  State get initialState => states.firstWhere((s) => s.isInitial);

  @override
  Set<String> get paths => {for (var event in events) '$id.$event'};

  StateNode findChild(String id) => states.firstWhere((s) => s.id == id);
}

abstract class StateNode {
  Set<String> get events;
  String get id;
  Action? get onEntry;
  Action? get onExit;
}

class Transition {
  final String? event;
  final Condition? condition;
  final String targetId;

  final Action? action;

  const Transition(this.targetId, {this.event, this.condition, this.action})
      : assert(event != null || condition != null);
}
