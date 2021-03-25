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
import 'dart:core';

import 'package:logging/logging.dart';
import 'package:statecharts/statecharts.dart';

final _log = Logger('transition');

class EventTransition<T> extends TransitionBase<T> implements Transition<T> {
  final String event;

  const EventTransition(targetId,
      {required this.event, Condition<T>? condition})
      : super(targetId, condition);

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

class NonEventTransition<T> extends TransitionBase<T> implements Transition<T> {
  final Duration? after;

  const NonEventTransition(targetId,
      {this.after, Condition<T>? condition, ignoreContext = false})
      : assert(after != null || condition != null),
        super(targetId, condition);

  @override
  bool matches(
          {String? anEvent,
          Duration? elapsedTime,
          T? context,
          ignoreContext = false}) =>
      (!ignoreContext && condition != null && meetsCondition(context)) ||
      (elapsedTime != null && elapsedTime.compareTo(after!) >= 0);
}

class NullTransition<T> implements Transition<T> {
  @override
  final condition = null;
  @override
  final targetId;

  NullTransition(this.targetId);

  @override
  bool matches(
      {String? anEvent,
      Duration? elapsedTime,
      T? context,
      ignoreContext = false}) {
    throw UnimplementedError();
  }
}

abstract class Transition<T> {
  Condition<T>? get condition;
  String get targetId;

  bool matches(
      {String? anEvent,
      Duration? elapsedTime,
      T? context,
      ignoreContext = false});
}

abstract class TransitionBase<T> implements Transition<T> {
  final Condition<T>? condition;
  final String targetId;

  const TransitionBase(this.targetId, this.condition);

  bool meetsCondition(T? context) =>
      condition == null || (context != null && condition!(context));
}
