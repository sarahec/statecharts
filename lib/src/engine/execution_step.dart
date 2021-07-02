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

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:quiver/core.dart';
import 'package:statecharts/statecharts.dart';

class ExecutionStep<T> {
  final RuntimeState<T> root;

  final Set<RuntimeState<T>> activeStates;
  final Iterable<RuntimeState<T>> entryStates;
  final Iterable<RuntimeState<T>> exitStates;
  final Set<RuntimeState<T>> selections;

  late final Map<String, RuntimeState<T>> lookupMap;

  ExecutionStep(this.root)
      : activeStates = {},
        entryStates = [],
        exitStates = [],
        selections = {},
        lookupMap = UnmodifiableMapView({
          for (var state in root.toIterable.where((s) => s.id != null))
            state.id!: state
        });

  ExecutionStep._(priorState, this.activeStates, this.entryStates,
      this.exitStates, this.selections)
      : root = priorState.root,
        lookupMap = priorState.lookupMap;

  @override
  int get hashCode =>
      hashObjects([root, activeStates, entryStates, exitStates, selections]);

  ExecutionStepBuilder<T> get toBuilder => ExecutionStepBuilder<T>._(this);

  @override
  bool operator ==(Object other) =>
      other is ExecutionStep<T> &&
      root == other.root &&
      IterableEquality().equals(activeStates, other.activeStates) &&
      IterableEquality().equals(entryStates, other.entryStates) &&
      IterableEquality().equals(exitStates, other.exitStates);

  /// Shorthand for [findState]
  @visibleForTesting
  RuntimeState<T>? operator [](String? id) => findState(id);

  RuntimeState<T>? findState(String? id) => lookupMap[id];
}

class ExecutionStepBuilder<T> {
  final ExecutionStep<T> priorState;

  /// Explicitly selected states from transitions
  final Set<RuntimeState<T>> selections;

  /// The fully-expanded set of active states built on the selections
  late final Set<RuntimeState<T>> activeStates;

  ExecutionStepBuilder._(this.priorState)
      : selections = Set.from(priorState.selections);

  Set<RuntimeState<T>> get entryStates =>
      UnmodifiableSetView(activeStates.difference(priorState.activeStates));

  Set<RuntimeState<T>> get exitStates =>
      UnmodifiableSetView(priorState.activeStates.difference(activeStates));

  void add(RuntimeState<T> state) => selections.add(state);

  ExecutionStep<T> build() {
    activeStates = buildActiveStates();
    return ExecutionStep<T>._(
        priorState, activeStates, entryStates, exitStates, selections);
  }

  /*
  @visibleForTesting
  Iterable<RuntimeState<T>> getChildStates(RuntimeState<T> state) =>
      state.substates.where((s) => !s.isHistoryState);
  */

  Set<RuntimeState<T>> buildActiveStates() {
    final _activeStates = <RuntimeState<T>>{};
    for (var s in selections) {
      _activeStates.addAll(s.ancestors());
    }
    for (var s in selections) {
      _activeStates.addAll(s.activeDescendents(selections));
    }
    return _activeStates;
  }

  ExecutionStep<T> initialize({required Iterable<String> idrefs}) {
    assert(selections.isEmpty);
    final states = [for (var id in idrefs) priorState.findState(id)!];
    selections.addAll(states);
    activeStates = buildActiveStates();
    return ExecutionStep<T>._(
        priorState, activeStates, entryStates, exitStates, selections);
  }

  void remove(RuntimeState<T> state) => selections.remove(state);

  // void addParallelChildrenToEnter(RuntimeState<T> state) {
  //   for (var child in getChildStates(state)) {
  //     if (!entryStates.any((s) => isDescendant(s, child))) {
  //       addDescendantStatesToEnter(child);
  //     }
  //   }
  // }
}
