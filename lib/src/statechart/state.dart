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
import 'package:quiver/core.dart';
import 'package:statecharts/statecharts.dart';

// final _log = Logger('State');

class HistoryState<T> extends State<T> {
  final String type;
  final Transition transition;

  HistoryState(String? id, this.transition, [this.type = 'deep'])
      : assert(type == 'shallow' || type == 'deep', 'invalid history type'),
        super(id);
}

class RootState<T> extends State<T> {
  RootState(id, substates,
      {transitions,
      onEntry,
      onExit,
      isInitial = false,
      isFinal = false,
      initialTransition,
      Iterable<String>? initialRefs})
      : assert(substates?.isNotEmpty, 'At least one substate required'),
        assert(
            (initialRefs == null && initialTransition == null) ||
                ((initialRefs == null) ^ (initialTransition == null)),
            'Cannot use initial attribute and <initial> child simultaneously'),
        super(id,
            transitions: transitions ?? [],
            onEntry: onEntry,
            onExit: onExit,
            initialRefs: initialRefs,
            initialTransition: initialTransition,
            isFinal: isFinal,
            substates: substates);
}

class State<T> {
  /// Unique identifier within its container
  final String? id;

  /// Declares this to be a final state
  final bool isFinal;

  /// Declares this to be a "parallel" state (all children active/inactive together)
  final bool isParallel;

  /// States contained within this one
  final Iterable<State<T>> substates;

  /// Transitions from this state
  final Iterable<Transition<T>> transitions;

  /// Action to be performed when this state or container is entered
  final Action<T>? onEntry;

  /// Action to be performed when this state or container is exited
  final Action<T>? onExit;

  final Iterable<String>? initialRefs;

  final Transition<T>? initialTransition;

  Iterable<Transition<T>> get initializingTransitions =>
      initialTransition != null
          ? [initialTransition!]
          : initialRefs?.map((ref) => Transition<T>(targets: [ref])) ??
              [
                Transition<T>(targets: [substates.first.id!])
              ];

  State(this.id,
      {this.transitions = const [],
      this.onEntry,
      this.onExit,
      this.isFinal = false,
      this.isParallel = false,
      this.substates = const [],
      this.initialRefs = const [],
      this.initialTransition});

  @override
  int get hashCode =>
      hashObjects([id, onEntry, onExit, transitions, /* isInitial, */ isFinal]);

  bool get isAtomic => substates.isEmpty;

  bool get isCompound => substates.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      other is State &&
      id == other.id &&
      isFinal == other.isFinal &&
      isParallel == other.isParallel &&
      onEntry == other.onEntry &&
      onExit == other.onExit &&
      initialTransition == other.initialTransition &&
      IterableEquality().equals(transitions, other.transitions) &&
      IterableEquality().equals(substates, other.substates) &&
      IterableEquality().equals(initialRefs, other.initialRefs);

  void enter(T? context) {
    if (onEntry != null && context != null) onEntry!(context);
  }

  void exit(T? context) {
    if (onExit != null && context != null) onExit!(context);
  }
}
