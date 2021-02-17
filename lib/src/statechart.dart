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
import 'package:meta/meta.dart';
import 'package:quiver/collection.dart';
import 'package:quiver/core.dart';

// final _log = Logger('statecharts/State');

/// Used for entry and exit actions (in and out of a state or container)
typedef Action<T> = void Function(T context);

/// Used in determing whether or not to take a transition
typedef Condition<T> = bool Function(T context);

class State<T> extends StateNode<T> {
  final bool isInitial;
  final List<Transition<T>> transitions;
  final Iterable<Statechart> substates;

  const State(id,
      {transitions = const <Transition>[],
      onEntry,
      onExit,
      this.isInitial = false,
      substates = const <Statechart>[]})
      : transitions = transitions,
        substates = substates,
        super(id, onEntry: onEntry, onExit: onExit);

  @override
  Set<String> get events =>
      {for (var t in transitions.where((t) => t.event != null)) t.event!};

  @override
  int get hashCode =>
      hashObjects([id, onEntry, onExit, transitions, isInitial, isTerminal]);

  bool get isAtomic => substates.isEmpty;

  bool get isTerminal => transitions.isEmpty;

  @override
  bool operator ==(Object other) =>
      other is State &&
      id == other.id &&
      onEntry == other.onEntry &&
      onExit == other.onExit &&
      listsEqual(transitions, other.transitions) &&
      isInitial == other.isInitial;

  @visibleForTesting
  bool hasTransitionFor({required String event}) => events.contains(event);

  @visibleForTesting
  Transition<T> transitionFor({required String event}) =>
      transitions.firstWhere((t) => t.event == event);
}

class Statechart<T> extends StateNode<T> {
  final Iterable<State<T>> states;

  const Statechart(id, this.states, {onEntry, onExit})
      : super(id, onEntry: onEntry, onExit: onExit);

  @override
  Set<String> get events {
    final result = <String>{};

    for (var s in states) {
      result.addAll(s.events);
    }
    return result;
  }

  State<T> get initialState => states.firstWhere((s) => s.isInitial);

  @visibleForTesting
  Set<String> get paths => {for (var event in events) '$id.$event'};

  StateNode<T> findState(String id) => states.firstWhere((s) => s.id == id);

  bool hasState(String id) => states.any((s) => s.id == id);
}

/// Common elements for states and state charts
abstract class StateNode<T> {
  /// Unique identifier within its container
  final String id;

  /// Action to be performed when this state or container is entered
  final Action<T>? onEntry;

  /// Action to be performed when this state or container is exited
  final Action<T>? onExit;

  const StateNode(this.id, {this.onEntry, this.onExit});

  Set<String> get events;

  void enter(T? context) {
    if (onEntry != null && context != null) onEntry!(context);
  }

  void exit(T? context) {
    if (onExit != null && context != null) onExit!(context);
  }
}

class Transition<T> {
  final Condition<T>? condition;
  final String? event;
  final String targetId;

  const Transition(this.targetId, {this.event, this.condition})
      : assert(event != null || condition != null);

  bool canExecute({String? event, T? context}) => this.event == null
      ? meetsCondition(context)
      : this.event == event && meetsCondition(context);

  bool meetsCondition(T? context) =>
      condition == null || (context != null && condition!(context));
}
