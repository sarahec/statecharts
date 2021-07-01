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

import 'runtime_state.dart';

class ExecutionStep<T> {
  final RuntimeState<T> root;

  final Iterable<RuntimeState<T>> activeStates;
  final Iterable<RuntimeState<T>> entryStates;
  final Iterable<RuntimeState<T>> exitStates;
  final Iterable<RuntimeState<T>> selections;

  late final Map<String, RuntimeState<T>> lookupMap;

  ExecutionStep(this.root)
      : activeStates = [],
        entryStates = [],
        exitStates = [],
        selections = [],
        lookupMap = {
          for (var state in root.toIterable.where((s) => s.id != null))
            state.id!: state
        };

  ExecutionStep._(this.root, this.activeStates, this.entryStates,
      this.exitStates, this.selections, this.lookupMap);

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

  final Set<RuntimeState<T>>
      _selections; // .sorted((a, b) => a.order - b.order);

  final Set<RuntimeState<T>> _activeStates;

  @visibleForTesting
  final _entryStates =
      <RuntimeState<T>>{}; // .sorted((a, b) => a.order - b.order);

  @visibleForTesting
  final exitStates = <RuntimeState<T>>{};

  final _additions = <RuntimeState<T>>{};
  final _removals = <RuntimeState<T>>{};

  ExecutionStepBuilder._(ExecutionStep<T> this.priorState)
      : _selections = Set.from(priorState.selections),
        _activeStates = Set<RuntimeState<T>>.from(priorState.activeStates);

  /// The fully-expanded set of active states built on the selections
  Iterable<RuntimeState<T>> get activeStates => _activeStates;
  Iterable<RuntimeState<T>> get entryStates => _entryStates;

  /// Explicitly selected states from transitions
  Iterable<RuntimeState<T>> get selections => _selections;

  void add(RuntimeState<T> state) => _additions.add(state);

  @visibleForTesting
  void addAncestors(RuntimeState<T> state,
      {RuntimeState<T>? upTo, required Set<RuntimeState<T>> intoSet}) {
    for (var anc in state.ancestors(upTo: upTo)) {
      _entryStates.add(anc);
      if (anc.isParallel) {
        // addParallelChildrenToEnter(anc, intoSet);
      }
    }
  }

  ExecutionStep<T> build() {
    _selections.removeAll(_removals);
    _selections.addAll(_additions);
    return ExecutionStep<T>._(priorState.root, _activeStates, _entryStates,
        exitStates, selections, priorState.lookupMap);
  }

  @visibleForTesting
  Iterable<RuntimeState<T>> getChildStates(RuntimeState<T> state) =>
      state.substates.where((s) => !s.isHistoryState);

  void initialize({required Iterable<String> idrefs}) {
    final states = [for (var id in idrefs) priorState.findState(id)!];
    _selections
      ..clear()
      ..addAll(states);
    // We can build the active list from scratch
    // collect nodes up to the root
    final ancestors = states.map((s) => s.ancestors()).expand((e) => e);
    _activeStates
      ..clear()
      ..addAll(ancestors);
    _activeStates.addAll(states);
    final selectionDescendents = _selections
        .map((s) => s.activeDescendents(_selections))
        .expand((e) => e);
    _activeStates.addAll(selectionDescendents);
    _entryStates.addAll(_activeStates);
  }

  ///  True if state1 descends from state2
  @visibleForTesting
  bool isDescendant(RuntimeState<T> state1, RuntimeState<T> state2) =>
      state1.ancestors().contains(state2);

  void remove(RuntimeState<T> state) => _removals.add(state);

  void replace(RuntimeState<T> oldState, RuntimeState<T> newState) {
    remove(oldState);
    add(newState);
  }

  // void addParallelChildrenToEnter(RuntimeState<T> state) {
  //   for (var child in getChildStates(state)) {
  //     if (!entryStates.any((s) => isDescendant(s, child))) {
  //       addDescendantStatesToEnter(child);
  //     }
  //   }
  // }
}
