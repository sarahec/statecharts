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
import 'package:quiver/core.dart';
import 'package:statecharts/statecharts.dart';

// final _log = Logger('State');

class State<T> {
  /// Unique identifier within its container
  final String? id;

  /// Declares this to be an initial state
  final bool isInitial;

  /// Declares this to be a final state
  final bool isFinal;

  final Iterable<State<T>> substates;
  final Iterable<Transition<T>> transitions;

  /// Action to be performed when this state or container is entered
  final Action<T>? onEntry;

  /// Action to be performed when this state or container is exited
  final Action<T>? onExit;

  /// Used to find the containing state (when this is a substate)
  late final State<T>? container;

  factory State(id,
      {Iterable<Transition<T>> transitions = const [],
      onEntry,
      onExit,
      isInitial = false,
      isFinal = false,
      Iterable<State<T>> substates = const []}) {
    final s = State<T>._(
        id, transitions, onEntry, onExit, isInitial, isFinal, substates);
    for (var probe in s.substates) {
      probe.container = s;
    }
    return s;
  }

  State._(this.id, this.transitions, this.onEntry, this.onExit, this.isInitial,
      this.isFinal, this.substates);

  @override
  int get hashCode => hashObjects(
      [id, container, onEntry, onExit, transitions, isInitial, isFinal]);

  State<T> get initialState => isInitial
      ? this
      : substates.firstWhere((s) => s.isInitial, orElse: () => substates.first);

  bool get isAtomic => substates.isEmpty;

  @override
  bool operator ==(Object other) =>
      other is State &&
      id == other.id &&
      onEntry == other.onEntry &&
      onExit == other.onExit &&
      container == other.container &&
      IterableEquality().equals(transitions, other.transitions) &&
      IterableEquality().equals(substates, other.substates) &&
      isInitial == other.isInitial;

  void enter(T? context) {
    if (onEntry != null && context != null) onEntry!(context);
  }

  void exit(T? context) {
    if (onExit != null && context != null) onExit!(context);
  }

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
