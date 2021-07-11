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

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:quiver/core.dart';
import 'package:statecharts/statecharts.dart';

// final _log = Logger('State');

enum HistoryDepth { SHALLOW, DEEP }

class HistoryState<T> implements State<T> {
  @override
  final String? id;
  final HistoryDepth type;
  final Transition transition;

  HistoryState(this.id, this.transition, [this.type = HistoryDepth.DEEP]);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
      'Not in History pseudo-state: ${invocation.memberName}');
}

class RootState<T> extends State<T> {
  final StateResolver<T> resolver;

  factory RootState(id, substates,
      {transitions = const [],
      onEntry,
      onExit,
      isFinal = false,
      isParallel = false,
      initialTransition,
      resolver}) {
    assert(substates.isNotEmpty, 'At least one substate required');
    final root = RootState<T>._(resolver ?? StateResolver<T>(), id, transitions,
        onEntry, onExit, isFinal, isParallel, substates, initialTransition)
      ..completeTree();
    root.resolver.complete(root);
    return root;
  }

  void completeTree() {
    var order = 1;
    void completeNode(State<T> node) {
      for (var s in node.substates) {
        s.parent = node;
        s.order = order++;
        completeNode(s);
      }
    }

    parent = null;
    this.order = 0;
    completeNode(this);
  }

  Future<State<T>?> find(String id) async => resolver.find(id);

  RootState._(this.resolver, id, transitions, onEntry, onExit, isFinal,
      isParallel, substates, initialTransition)
      : super._(id, transitions.cast<Future<Transition<T>>>(), onEntry, onExit,
            isFinal, isParallel, substates, initialTransition);
}

class State<T> {
  late final int order;

  /// Unique identifier within its container
  final String? id;

  /// Declares this to be a final state
  final bool isFinal;

  /// Declares this to be a "parallel" state (all children active/inactive together)
  final bool isParallel;

  /// States contained within this one
  final Iterable<State<T>> substates;

  /// Transitions from this state
  final Iterable<Future<Transition<T>>> transitions;

  /// Action to be performed when this state or container is entered
  final Action<T>? onEntry;

  /// Action to be performed when this state or container is exited
  final Action<T>? onExit;

  final Transition<T>? initialTransition;

  late final State<T>? parent;

  factory State(id,
      {Iterable<Future<Transition<T>>> transitions = const [],
      onEntry,
      onExit,
      isFinal = false,
      isParallel = false,
      substates = const [],
      Transition<T>? initialTransition}) {
    return State._(id, transitions, onEntry, onExit, isFinal, isParallel,
        substates.cast<State<T>>(), initialTransition);
  }

  State._(this.id, this.transitions, this.onEntry, this.onExit, this.isFinal,
      this.isParallel, this.substates, this.initialTransition);

  @override
  int get hashCode =>
      hashObjects([id, onEntry, onExit, transitions, /* isInitial, */ isFinal]);

  @override
  bool operator ==(Object other) =>
      other is State<T> &&
      id == other.id &&
      isFinal == other.isFinal &&
      isParallel == other.isParallel &&
      onEntry == other.onEntry &&
      onExit == other.onExit &&
      initialTransition == other.initialTransition &&
      IterableEquality().equals(transitions, other.transitions) &&
      IterableEquality().equals(substates, other.substates);
}
