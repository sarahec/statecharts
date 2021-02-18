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

import 'package:statecharts/statecharts.dart';

class NonEventTransition<T> extends TransitionBase<T> {
  final Duration? after;

  const NonEventTransition(targetId, {this.after, Condition<T>? condition})
      : assert(after != null || condition != null),
        super(targetId, condition);

  bool matches({String? event, Duration? elapsedTime, T? context}) =>
      meetsCondition(context) || (elapsedTime != null && elapsedTime >= after!);
}

class Transition<T> extends TransitionBase<T> {
  final String event;

  const Transition(targetId, {required this.event, Condition<T>? condition})
      : super(targetId, condition);

  bool matches({String? event, Duration? elapsedTime, T? context}) =>
      this.event == event! && meetsCondition(context);
}

abstract class TransitionBase<T> {
  final Condition<T>? condition;
  final String targetId;

  const TransitionBase(this.targetId, this.condition);

  bool meetsCondition(T? context) =>
      condition == null || (context != null && condition!(context));
}
