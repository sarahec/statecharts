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
// See the License for the specific language goveRuntimeState<T>ning permissions and
// limitations under the License.

import 'package:meta/meta.dart';
import 'package:statecharts/statecharts.dart';

class HistoryContainer<T> {
  @visibleForTesting
  final Map<RuntimeState<T>, Iterable<RuntimeState<T>>> history;

  HistoryContainer() : history = {};

  HistoryContainer.from(HistoryContainer<T> prior)
      : history = Map.from(prior.history);

  HistoryContainer addAll(
      {required Iterable<RuntimeState<T>> exitStates,
      required Iterable<RuntimeState<T>> activeStates}) {
    final newContainer = HistoryContainer.from(this);
    final storedCopy = List.of(activeStates);
    for (var es in exitStates) {
      newContainer.history[es] = storedCopy;
    }
    return newContainer;
  }

  bool contains(RuntimeState<T> state) => history.containsKey(state);

  Iterable<RuntimeState<T>> resolve(RuntimeState<T> state) =>
      state.isHistoryState ? history[state] ?? [] : [];
}
