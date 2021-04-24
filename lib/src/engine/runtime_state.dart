/**
 * Copyright 2021 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:collection/collection.dart';
import 'package:statecharts/statecharts.dart';

class RuntimeState<T> implements State<T> {
  final State<T> state;
  final RuntimeState<T>? parent;
  final int order;
  @override
  late final Iterable<RuntimeState<T>> substates;
  @override
  late final Iterable<RuntimeTransition<T>> transitions;

  RuntimeState(this.state, this.order, [this.parent]);

  static RuntimeState<T> wrapSubtree<T>(State<T> state,
      [order = 0, RuntimeState<T>? parent]) {
    var index = order;

    // track results to attach targetState to wrapped transactions
    final stateMap = <String, RuntimeState<T>>{};
    final transitions = <RuntimeTransition<T>>[];

    RuntimeState<T> _wrap(state, parent) {
      final wrapped = RuntimeState<T>(state, index++, parent);
      wrapped.transitions = [
        for (var t in state.transitions) RuntimeTransition(t, wrapped)
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
      t.targetStates = [for (var s in t.targets) stateMap[s]!];
    }
    return wrappedRoot;
  }

  @override
  void enter(T? context) => state.enter(context);

  @override
  void exit(T? context) => state.exit(context);

  @override
  String? get id => state.id;

  @override
  State<T> get initialSubstate => state.initialSubstate;

  @override
  bool get isAtomic => state.isAtomic;

  @override
  bool get isCompound => state.isCompound;

  @override
  bool get isFinal => state.isFinal;

  bool get isHistoryState => state is HistoryState<T>;

  bool get isScxmlState => state is RootState<T>;

  @override
  bool get isInitial => throw UnimplementedError();

  @override
  bool get isParallel => state.isParallel;

  @override
  Action<T>? get onEntry => state.onEntry;

  @override
  Action<T>? get onExit => state.onExit;

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
}