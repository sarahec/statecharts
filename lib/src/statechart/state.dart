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
import 'package:meta/meta.dart';
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

  State(this.id,
      {this.transitions = const [],
      this.onEntry,
      this.onExit,
      this.isInitial = false,
      this.isFinal = false,
      this.substates = const []});

  @override
  int get hashCode =>
      hashObjects([id, onEntry, onExit, transitions, isInitial, isFinal]);

  // TODO move to an extension used by the state configuration
  bool get hasExplicitInitialSubstate => substates.any((s) => s.isInitial);

  State<T> get initialState => isInitial ? this : initialSubstate;

  State<T> get initialSubstate =>
      substates.firstWhere((s) => s.isInitial, orElse: () => substates.first);

  bool get isAtomic => substates.isEmpty;

  Iterable<State<T>> get toIterable sync* {
    yield* generateIterable(this);
  }

  @override
  bool operator ==(Object other) =>
      other is State &&
      id == other.id &&
      onEntry == other.onEntry &&
      onExit == other.onExit &&
      IterableEquality().equals(transitions, other.transitions) &&
      IterableEquality().equals(substates, other.substates) &&
      isInitial == other.isInitial;

  void enter(T? context) {
    if (onEntry != null && context != null) onEntry!(context);
  }

  void exit(T? context) {
    if (onExit != null && context != null) onExit!(context);
  }

  @visibleForTesting
  Iterable<State<T>> generateIterable(State<T> node) sync* {
    yield node;
    for (var child in node.substates) {
      yield* generateIterable(child);
    }
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

class HistoryState<T> extends State<T> {
  final String type;
  final Transition transition;

  HistoryState(String? id, this.transition, [this.type = 'deep'])
      : assert(type == 'shallow' || type == 'deep', 'invalid history type'),
        super(id);
}

class SCXMLState<T> extends State<T> {
  /// Defines the substate to use initially (`<initial>` child)
  final Transition<T>? initialTransition;

  /// Defines the initial substates (`initial` attribute)
  final String? initialStateIDs;

  SCXMLState(id,
      {transitions = const [],
      onEntry,
      onExit,
      isInitial = false,
      isFinal = false,
      substates = const [],
      this.initialTransition,
      this.initialStateIDs})
      : assert(
            (initialStateIDs == null && initialTransition == null) ||
                ((initialStateIDs == null) ^ (initialTransition == null)),
            'Cannot use initial attribute and <initial> child simultaneously'),
        super(id,
            transitions: transitions,
            onEntry: onEntry,
            onExit: onExit,
            isInitial: isInitial,
            isFinal: isFinal,
            substates: substates);
}