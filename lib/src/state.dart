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

class State<T> implements StateNode<T> {
  @override
  final String id;
  final bool isInitial;
  @override
  final Action<T>? onEntry;
  @override
  final Action<T>? onExit;
  final List<Transition<T>>? transitions;

  const State(this.id,
      {this.transitions, this.onEntry, this.onExit, this.isInitial = false});

  @override
  Set<String> get events => transitions == null
      ? {}
      : {for (var t in transitions!.where((t) => t.event != null)) t.event!};

  @override
  int get hashCode =>
      hashObjects([id, onEntry, onExit, transitions, isInitial, isTerminal]);

  bool get isTerminal => transitions == null || transitions!.isEmpty;

  @override
  bool operator ==(Object other) =>
      other is State &&
      id == other.id &&
      onEntry == other.onEntry &&
      onExit == other.onExit &&
      listsEqual(transitions, other.transitions) &&
      isInitial == other.isInitial;

  void enter(T? context) {
    if (onEntry != null && context != null) onEntry!(context);
  }

  void exit(T? context) {
    if (onExit != null && context != null) onExit!(context);
  }

  bool hasTransitionFor({required String event}) => events.contains(event);

  Transition<T> transitionFor({required String event}) =>
      transitions!.firstWhere((t) => t.event == event);
}

class Statechart<T> implements StateContainer<T> {
  @override
  final String id;
  @override
  final Action<T>? onEntry;
  @override
  final Action<T>? onExit;
  final StateMachine<T> stateMachine;

  const Statechart(this.id, this.stateMachine, {this.onEntry, this.onExit});

  @override
  Set<String> get events => stateMachine.events;

  @override
  State<T> get initialState => stateMachine.initialState;

  @override
  Set<String> get paths =>
      {for (var event in stateMachine.events) '$id.$event'};
}

abstract class StateContainer<T> extends StateNode<T> {
  State get initialState;
  Set<String> get paths;
}

class StateMachine<T> implements StateContainer<T> {
  @override
  final String id;
  @override
  final Action<T>? onEntry;
  @override
  final Action<T>? onExit;
  final Iterable<State<T>> states;

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
  State<T> get initialState => states.firstWhere((s) => s.isInitial);

  @override
  Set<String> get paths => {for (var event in events) '$id.$event'};

  StateNode<T> findChild(String id) => states.firstWhere((s) => s.id == id);
}

abstract class StateNode<T> {
  Set<String> get events;
  String get id;
  Action<T>? get onEntry;
  Action<T>? get onExit;
}

class Transition<T> {
  final Condition<T>? condition;
  final String? event;
  final String targetId;

  bool canExecute({String? event, T? context}) => this.event == null
      ? meetsCondition(context)
      : this.event == event && meetsCondition(context);

  bool meetsCondition(T? context) =>
      condition == null || (context != null && condition!(context));

  const Transition(this.targetId, {this.event, this.condition})
      : assert(event != null || condition != null);
}
