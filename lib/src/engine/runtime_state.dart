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

class RuntimeState<T> implements State<T>, Comparable {
  final State<T> state;
  final RuntimeState<T>? parent;
  final int order;
  @override
  late final Iterable<RuntimeState<T>> substates;
  @override
  late final Iterable<RuntimeTransition<T>> transitions;

  RuntimeState(this.state, this.order, [this.parent]);

  @override
  int get hashCode => hash3(state, parent, order);

  @override
  String? get id => state.id;

  @override
  // TODO: implement initializingTransitions
  Iterable<Transition<T>> get initializingTransitions =>
      throw UnimplementedError();

  @override
  Iterable<String>? get initialRefs => state.initialRefs;

  @override
  // TODO: implement initialTransition
  Transition<T>? get initialTransition => throw UnimplementedError();

  @override
  bool get isAtomic => state.isAtomic;

  @override
  bool get isCompound => state.isCompound;

  @override
  bool get isFinal => state.isFinal;

  bool get isHistoryState => state is HistoryState<T>;

  @override
  bool get isParallel => state.isParallel;

  bool get isScxmlState => state is RootState<T>;

  @override
  Action<T>? get onEntry => state.onEntry;

  @override
  Action<T>? get onExit => state.onExit;

  Iterable<RuntimeState<T>> get toIterable sync* {
    Iterable<RuntimeState<T>> _toIterable(RuntimeState<T> node) sync* {
      yield node;
      for (var child in node.substates) {
        yield* _toIterable(child);
      }
    }

    yield* _toIterable(this);
  }

  @override
  bool operator ==(Object other) =>
      other is RuntimeState<T> &&
      state == other.state &&
      order == other.order &&
      parent == other.parent;

  Iterable<RuntimeState<T>> activeDescendents(
      Set<RuntimeState<T>> selections) sync* {
    Iterable<RuntimeState<T>> _active(RuntimeState<T> node) sync* {
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
  Iterable<RuntimeState<T>> ancestors({RuntimeState<T>? upTo}) sync* {
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

  @override
  int compareTo(other) => order.compareTo(other.order);

  @override
  void enter(T? context) => state.enter(context);

  @override
  void exit(T? context) => state.exit(context);

  RuntimeState<T>? find(String id) =>
      toIterable.firstWhereOrNull((element) => element.id == id);

  RuntimeTransition<T>? getTransition(String toState) =>
      transitions.firstWhereOrNull((t) => t.targets.contains(toState));

  bool hasTransition(String toState) =>
      transitions.any((t) => t.targets.contains(toState));

  @override
  String toString() =>
      super.toString() +
      '(state: $state,  parent id:${parent?.id}, order: $order}';

  Transition<T>? transitionFor(
          {String? event,
          Duration? elapsedTime,
          T? context,
          ignoreContext = false}) =>
      transitions.firstWhereOrNull((t) => t.matches(
          anEvent: event,
          elapsedTime: elapsedTime,
          context: context,
          ignoreContext: ignoreContext));

  static RuntimeState<T> wrapSubtree<T>(State<T> state,
      [order = 0, RuntimeState<T>? parent]) {
    var index = order;

    // track results to attach targetState to wrapped transactions
    final stateMap = <String, RuntimeState<T>>{};
    final transitions = <RuntimeTransition<T>>[];

    RuntimeState<T> _wrap(state, parent) {
      final wrapped = RuntimeState<T>(state, index++, parent);
      var position = 0;
      wrapped.transitions = [
        for (var t in state.transitions)
          RuntimeTransition(t, wrapped, position++)
      ];
      transitions.addAll(wrapped.transitions);
      wrapped.substates = [
        for (var probe in state.substates) _wrap(probe, wrapped)
      ];
      if (wrapped.id != null) stateMap[wrapped.id!] = wrapped;
      return wrapped;
    }

    final wrappedRoot = _wrap(state, parent);
    for (var t in transitions) {
      t.attachTargetStates(stateMap);
    }
    return wrappedRoot;
  }
}

// Testing extensions
extension IDs on Iterable<RuntimeState> {
  Iterable<String> get ids => map((e) => e.id ?? 'null');
}
