// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//
//      https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:core';

import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:statecharts/statecharts.dart';

final _log = Logger('transition');

/// A transition based on a named event such as `'turnOn'`.
///
/// It's easiest to create one of these using one of these using the [Transition]
/// factory method.
///
/// Note that transitions, like states, are immutable once created.
@immutable
class EventTransition<T> extends Transition<T> {
  /// The event name to match
  final String event;

  EventTransition(
      {Iterable<String> targets = const [],
      required this.event,
      Condition<T>? condition,
      type = TransitionType.externalTransition,
      Action<T>? action})
      : super._(targets, condition, type, action);

  /// Tests whether this transition matches based on [event] and/or [condition],
  /// ignoring [elapsedTime].
  ///
  /// [anEvent] The name of the event to match. If none is specified,
  /// it could still match on [condition].
  /// [elapsedTime] Ignored.
  /// [context] The data tested by the condition and modified by [State.onEntry]
  /// and [State.onExit].
  /// [ignoreContext] If true, skip the [condition] check (forces it to be true).
  @override
  bool matches(
      {String? anEvent,
      Duration? elapsedTime,
      T? context,
      ignoreContext = false}) {
    // using compareTo instead of == as null safety appears to break == between
    // String? and String
    final found = anEvent != null &&
        event.compareTo(anEvent) == 0 &&
        (ignoreContext || meetsCondition(context));
    _log.finest(() => 'Matching on event $anEvent: $found');
    return found;
  }
}

/// A transition based on time or the [condition] field.
///
/// It's easiest to create one of these using one of these using the [Transition]
/// factory method.
///
/// Note that transitions, like states, are immutable once created.

class NonEventTransition<T> extends Transition<T> {
  /// Time to trigger this. If null, this trabnsition triggers on its [condition]
  final Duration? after;

  NonEventTransition(
      {Iterable<String> targets = const [],
      this.after,
      Condition<T>? condition,
      type = TransitionType.externalTransition,
      Action<T>? action})
      : super._(targets, condition, type, action);

  /// Tests whether this transition matches based on [elapsedTime] and/or [condition],
  /// ignoring [anEvent].
  ///
  /// [anEvent] Ignored.
  /// [elapsedTime] The total time since the last event was triggered.
  /// [context] The data tested by the condition and modified by [State.onEntry]
  /// and [State.onExit].
  /// [ignoreContext] If true, skip the [condition] check (forces it to be true).
  @override
  bool matches(
          {String? anEvent,
          Duration? elapsedTime,
          T? context,
          ignoreContext = false}) =>
      (!ignoreContext && condition != null && meetsCondition(context)) ||
      (elapsedTime != null && elapsedTime.compareTo(after!) >= 0);
}

/// Base class for all transitions.
abstract class Transition<T> {
  /// If true, this transition should be triggered.
  final Condition<T>? condition;

  /// The actual target states.
  late final Iterable<State<T>> targetStates;

  /// IDs of all of the target states to activate.
  final Iterable<String> targets;

  /// Is this triggered by internal or external events?
  final TransitionType type;

  /// Reference back to the containing state.
  late final State<T>? source;

  /// An action to take when the transition is triggered.
  final Action<T>? action;

  /// Create the appropriate subclass based on the parameters.
  factory Transition(
          {Iterable<String> targets = const [],
          String? event,
          Condition<T>? condition,
          Duration? after,
          type = TransitionType.externalTransition,
          Action<T>? action}) =>
      event != null
          ? EventTransition<T>(
              event: event,
              targets: targets,
              condition: condition,
              type: type,
              action: action)
          : NonEventTransition<T>(
              after: after,
              targets: targets,
              condition: condition,
              type: type,
              action: action);

  Transition._(this.targets, this.condition, this.type, this.action);

  /// See subclasses
  bool matches(
      {String? anEvent,
      Duration? elapsedTime,
      T? context,
      ignoreContext = false});

  /// Tests [condition]
  ///
  /// If there is no condition or context, returns `true` anyways.
  bool meetsCondition(T? context) =>
      condition == null || (context != null && condition!(context));

  /// Populates [targetStates] from [targets].
  void resolveStates(State<T> parent, Map<String, State<T>> stateMap) {
    source = parent;
    targetStates = [for (var s in targets) stateMap[s]!];
  }

  @override
  String toString() => '(targets: $targets)';
}

/// Where  the transition should receive its events from.
enum TransitionType { internalTransition, externalTransition }
