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
import 'package:meta/meta.dart';
import 'package:quiver/core.dart';
import 'package:statecharts/statecharts.dart';

class RootState<T> extends State<T> {
  final StateResolver<T> resolver;
  var _stateMap;

  @visibleForTesting
  RootState(this.resolver, id, transitions, onEntry, onExit, isFinal,
      isParallel, substates, initialTransition)
      : super._(id, transitions.cast<Future<Transition<T>>>(), onEntry, onExit,
            isFinal, isParallel, substates, initialTransition);

  @override
  bool operator ==(Object other) =>
      other is RootState<T> &&
      id == other.id &&
      isFinal == other.isFinal &&
      isParallel == other.isParallel &&
      IterableEquality().equals(substates, other.substates);

  State<T>? find(String id) {
    _stateMap ??= {
      for (var s in toIterable.where((s1) => s1.id != null)) s.id!: s
    };
    return _stateMap[id];
  }

  @visibleForTesting
  Future<RootState<T>> finishTree() async {
    var order = 1;

    Future<void> finishNode(State<T> node) async {
      for (var s in node.substates) {
        s.parent = node;
        s.order = order++;
        await Future.wait(s.transitions).then((transitions) {
          for (var t in transitions) {
            t.source = s;
          }
        });
        await finishNode(s);
      }
    }

    parent = null;
    this.order = 0;
    await finishNode(this);
    return this;
  }

  @override
  String toString() => "('$id', $substates)";

  static Future<RootState<T>> newRoot<T>(id, substates,
      {transitions = const [],
      onEntry,
      onExit,
      isFinal = false,
      isParallel = false,
      initialTransition,
      resolver}) async {
    assert(substates.isNotEmpty, 'At least one substate required');
    var res = resolver ?? StateResolver<T>();
    final root = RootState<T>(res, id, transitions, onEntry, onExit, isFinal,
        isParallel, substates, initialTransition);
    res.complete(root);
    return Future.value(root).then((tree) => tree.finishTree());
  }
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

  final Future<Transition<T>>? initialTransition;

  late final State<T>? parent;

  factory State(id,
      {Iterable<Future<Transition<T>>> transitions = const [],
      Action<T>? onEntry,
      Action<T>? onExit,
      bool isFinal = false,
      bool isParallel = false,
      Iterable<State<T>> substates = const [],
      Future<Transition<T>>? initialTransition}) {
    return State._(id, transitions, onEntry, onExit, isFinal, isParallel,
        substates.cast<State<T>>(), initialTransition);
  }

  State._(this.id, this.transitions, this.onEntry, this.onExit, this.isFinal,
      this.isParallel, this.substates, this.initialTransition);

  bool get containsHistoryState => substates.any((s) => s is HistoryState<T>);

  @override
  int get hashCode => hashObjects([id, isParallel, isFinal, substates]);

  bool get isAtomic => substates.isEmpty;

  bool get isCompound => substates.isNotEmpty;

  Iterable<State<T>> get toIterable sync* {
    Iterable<State<T>> _toIterable(State<T> node) sync* {
      yield node;
      for (var child in node.substates) {
        yield* _toIterable(child);
      }
    }

    yield* _toIterable(this);
  }

  @override
  bool operator ==(Object other) =>
      other is State<T> &&
      id == other.id &&
      isFinal == other.isFinal &&
      isParallel == other.isParallel &&
      IterableEquality().equals(substates, other.substates);

  Iterable<State<T>> activeDescendents(Set<State<T>> selections) sync* {
    Iterable<State<T>> _active(State<T> node) sync* {
      yield node;
      if (node.isAtomic) return;
      final child =
          node.substates.firstWhereOrNull((c) => selections.contains(c)) ??
              node.substates.first;
      yield* _active(child);
    }

    yield* _active(this);
  }

  /// Finds the ancestors of a state
  ///
  /// If [upTo] is null, returns the set of all ancestors (parents)
  /// from this up to (and including) the top of tree (`parent == null`).
  /// If [upTo] is not null, return all ancestors up to but *not*
  /// including [upTo].
  ///
  /// Special case: the ancestor of the root state is itself (returned once).
  Iterable<State<T>> ancestors({State<T>? upTo}) sync* {
    if (parent == null) {
      yield this;
      return;
    }
    if (upTo != null && upTo == this) return;
    var probe = parent;
    while (probe != null && upTo != probe) {
      yield probe;
      probe = probe.parent;
      if (probe == null) break;
    }
  }

  void enter(T? context, [EngineCallback? callback]) {
    if (onEntry != null && context != null) onEntry!(context, callback);
  }

  void exit(T? context, [EngineCallback? callback]) {
    if (onExit != null && context != null) onExit!(context, callback);
  }

  @override
  String toString() => "('$id', $substates)";

  Future<Transition<T>?> transitionFor(
          {String? event,
          Duration? elapsedTime,
          T? context,
          bool? ignoreContext = false}) async =>
      Future.wait(transitions).then((transitionList) =>
          transitionList.firstWhereOrNull((t) => t.matches(
              anEvent: event,
              elapsedTime: elapsedTime,
              context: context,
              ignoreContext: ignoreContext)));
}
