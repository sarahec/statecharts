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

/// Contains the results of one execution step.
abstract class ExecutionStep<T> {
  ExecutionStep<T> applyTransitions(Iterable<Transition<T>> transitions);

  /// Create a new step after adding and removing states.
  ExecutionStep<T> applyChanges({
    Iterable<State<T>> remove = const [],
    Iterable<State<T>> add = const [],
  });

  /// All active states, including resolved history states.
  ///
  /// This rebuilds the entire tree from scratch (for now)
  Set<State<T>> get activeStates;

  /// All states that need [State.onEntry] called, in order.
  Iterable<State<T>> get entryStates;

  /// All states that need [State.onExit] called, in reverse order.
  Iterable<State<T>> get exitStates;

  /// True if any values have changed in this step.
  bool get isChanged;

  /// The root of the tree
  RootState<T> get root;

  /// Explicitly selected states (from transitions)
  Set<State<T>> get selections;

  /// The transitions taken.
  Iterable<Transition<T>>? get transitions;
}
