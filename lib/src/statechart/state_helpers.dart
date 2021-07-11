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
import 'package:statecharts/statecharts.dart';

extension StateHelpers<T> on State<T> {
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

  void enter(T? context) {
    if (onEntry != null && context != null) onEntry!(context);
  }

  void exit(T? context) {
    if (onExit != null && context != null) onExit!(context);
  }

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

  bool get containsHistoryState => substates.any((s) => s is HistoryState<T>);

  Future<Transition<T>?> transitionFor(
          {String? event,
          Duration? elapsedTime,
          T? context,
          ignoreContext = false}) async =>
      Future.wait(transitions).then((transitionList) =>
          transitionList.firstWhereOrNull((t) => t.matches(
              anEvent: event,
              elapsedTime: elapsedTime,
              context: context,
              ignoreContext: ignoreContext)));
}
