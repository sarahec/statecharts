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

import 'package:statecharts/statecharts.dart';

class RuntimeTransition<T> implements Transition<T> {
  final Transition<T> transition;
  final RuntimeState<T> source;
  late final Iterable<RuntimeState<T>> targetStates;

  RuntimeTransition(this.transition, this.source);

  @override
  Condition<T>? get condition => transition.condition;

  @override
  bool matches(
          {String? anEvent,
          Duration? elapsedTime,
          T? context,
          ignoreContext = false}) =>
      transition.matches(
          anEvent: anEvent,
          elapsedTime: elapsedTime,
          context: context,
          ignoreContext: ignoreContext);

  @override
  bool meetsCondition(T? context) => transition.meetsCondition(context);

  @override
  Iterable<String> get targets => transition.targets;

  @override
  String get type => transition.type;

  void attachTargetStates(Map<String, RuntimeState<T>> stateMap) {
    targetStates = [for (var s in transition.targets) stateMap[s]!];
  }
}
