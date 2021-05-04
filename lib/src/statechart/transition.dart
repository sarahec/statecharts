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

import 'package:collection/collection.dart';
import 'package:logging/logging.dart';
import 'package:quiver/core.dart';
import 'package:statecharts/statecharts.dart';

final _log = Logger('transition');

class EventTransition<T> extends Transition<T> {
  final String event;

  const EventTransition(
      {Iterable<String> targets = const [],
      required this.event,
      Condition<T>? condition,
      String type = 'external'})
      : super(targets, condition, type);

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

  @override
  int get hashCode => hash4(event, targets, condition, type);

  @override
  bool operator ==(Object other) =>
      other is EventTransition<T> &&
      event == other.event &&
      condition == other.condition &&
      IterableEquality().equals(targets, other.targets) &&
      type == other.type;
}

class NonEventTransition<T> extends Transition<T> {
  final Duration? after;

  const NonEventTransition(
      {Iterable<String> targets = const [],
      this.after,
      Condition<T>? condition,
      String type = 'external'})
      : super(targets, condition, type);

  @override
  bool matches(
          {String? anEvent,
          Duration? elapsedTime,
          T? context,
          ignoreContext = false}) =>
      (!ignoreContext && condition != null && meetsCondition(context)) ||
      (elapsedTime != null && elapsedTime.compareTo(after!) >= 0);

  @override
  int get hashCode => hash4(targets, after, condition, type);

  @override
  bool operator ==(Object other) =>
      other is NonEventTransition<T> &&
      after == other.after &&
      condition == other.condition &&
      IterableEquality().equals(targets, other.targets) &&
      type == other.type;
}

abstract class Transition<T> {
  final Condition<T>? condition;
  final Iterable<String> targets;
  final String type;

  const Transition(this.targets, this.condition, this.type)
      : assert(type == 'internal' || type == 'external',
            'transition type must be internal or external, found $type');

  bool matches(
      {String? anEvent,
      Duration? elapsedTime,
      T? context,
      ignoreContext = false});

  bool meetsCondition(T? context) =>
      condition == null || (context != null && condition!(context));

  @override
  int get hashCode => hash3(condition, targets, type);

  @override
  bool operator ==(Object other) =>
      other is Transition<T> &&
      condition == other.condition &&
      IterableEquality().equals(targets, other.targets) &&
      type == other.type;
}
