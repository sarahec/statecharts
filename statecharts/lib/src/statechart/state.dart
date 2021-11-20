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
import 'package:statecharts/statecharts.dart';

/// Defines the starting node for a statechart.
///
/// This node contains the entire statechart and defines the starting
/// transition. Note the use of a [StateResolver] to create transitions
/// from a state ID.
///
/// ```
/// const turnOn = 'turnOn';
/// const turnOff = 'turnOff';
/// final stateOff = State<Lightbulb>('off',
///    transitions: [
///     Transition(targets: ['on'], event: turnOn)
///   ],
///   onEntry: (b, _) => b!.isOn = false);
/// final stateOn = State<Lightbulb>('on',
///    transitions: [
///      Transition(targets: ['off'], event: turnOff)
///    ],
///    onEntry: (b, _) => b!.isOn = true,
///    onExit: (b, _) {
///      b!.cycleCount += 1;
///    });
///
/// final lightswitch = RootState<Lightbulb>(
///    'lightswitch',
///    [
///      stateOff,
///      stateOn,
///    ]);
/// ```
///
class RootState<T> extends State<T> {
  late final Map<String, State<T>> stateMap;

  /// The number of nodes in this tree
  late final int size;

  /// Create the root node.
  RootState(id,
      {required Iterable<State<T>> substates,
      Iterable<Transition<T>> transitions = const [],
      Action? onEntry,
      Action? onExit,
      bool isFinal = false,
      bool isParallel = false,
      Transition<T>? initialTransition})
      : assert(substates.isNotEmpty, 'At least one substate required'),
        super(id,
            substates: substates,
            transitions: transitions,
            onEntry: onEntry,
            onExit: onExit,
            isFinal: isFinal,
            isParallel: isParallel,
            initialTransition: initialTransition) {
    stateMap = {
      for (var s in toIterable.where((s1) => s1.id != null)) s.id!: s
    };
    order = 0;
    parent = null;
    resolveTransitions(stateMap);
    finishTree();
    size = toIterable.length;
  }

  // Resolve the transition futures into transitions pointing to
  // actual states.
  /// Locate a state by ID. Returns null if not found.
  State<T>? find(String id) => stateMap[id];

  @visibleForOverriding
  void finishTree() {
    var _order = 1;

    void finishSubstates(State<T> node) {
      for (var s in node.substates) {
        s.parent = node;
        s.order = _order++;
        s.resolveTransitions(stateMap);
        finishSubstates(s);
      }
    }

    finishSubstates(this);
  }
}

class State<T> {
  /// Index into its parent's substates
  late final int order;

  /// Unique identifier within its container (optional)
  final String? id;

  /// Declares this to be a final state
  final bool isFinal;

  /// Declares this to be a "parallel" state (all children active/inactive together)
  final bool isParallel;

  /// States contained within this one
  final Iterable<State<T>> substates;

  /// All transitions from this state.
  final Iterable<Transition<T>> transitions;

  /// Action to be performed when this state or container is entered
  final Action<T>? onEntry;

  /// Action to be performed when this state or container is exited
  final Action<T>? onExit;

  /// The transition to run first.
  ///
  /// If null, the first substate is entered.
  final Transition<T>? initialTransition;

  /// This node's parent (assigned late)
  late final State<T>? parent;

  /// Creates a new [State]
  ///
  /// [transitions] If present, the available transitions out of this state.
  /// [onEntry] Called when this state is entered.
  /// [onExit] Called when this state is exited.
  /// [isFinal] True if this a final state.
  /// [isParallel] True if this is a parallel state.
  /// [substates] The child states of this state, if any.
  /// [initialTransition] A transition designating which substate shoud be
  /// activated on entry.
  State(this.id,
      {this.transitions = const [],
      this.onEntry,
      this.onExit,
      this.isFinal = false,
      this.isParallel = false,
      this.substates = const [],
      this.initialTransition});

  /// Are any of the immediate substates a history state?
  bool get containsHistoryState => substates.any((s) => s is HistoryState<T>);

  /// The states referenced by [initialTransition].
  Iterable<State<T>> get initialStates =>
      initialTransition?.targetStates ?? [substates.first];

  /// True if this has no substates (i.e. is a leaf node)
  bool get isAtomic => substates.isEmpty;

  /// True if this has at least one substate.
  bool get isCompound => substates.isNotEmpty;

  /// Used by [toString] to show IDs of substates, not the substates themselves.
  Iterable<String> get substateIDs => substates.map((s) => s.id ?? '_');

  /// Walks this subtree in depth-first order.
  Iterable<State<T>> get toIterable sync* {
    Iterable<State<T>> _toIterable(State<T> node) sync* {
      yield node;
      for (var child in node.substates) {
        yield* _toIterable(child);
      }
    }

    yield* _toIterable(this);
  }

  /// Finds the ancestors of a state
  ///
  /// If [upTo] is null, returns the set of all ancestors (parents)
  /// from this up to (and including) the top of tree (`parent == null`).
  /// If [upTo] is not null, return all ancestors up to but *not*
  /// including [upTo].
  Iterable<State<T>> ancestors({State<T>? upTo}) sync* {
    if (parent == null) {
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

  /// Whether this state descends from another.
  bool descendsFrom(State<T> other) => other.ancestors().contains(this);

  /// Calls [onEntry]  with the given context (if they are both non-null).
  void enter(T? context, [EngineCallback? callback]) {
    if (onEntry != null && context != null) onEntry!(context, callback);
  }

  /// Calls [onExit]  with the given context (if they are both non-null).
  void exit(T? context, [EngineCallback? callback]) {
    if (onExit != null && context != null) onExit!(context, callback);
  }

  /// Adds target states and source reference to all transitions.
  void resolveTransitions(Map<String, State<T>> stateMap) {
    initialTransition?.resolveStates(this, stateMap);
    for (var t in transitions) {
      t.resolveStates(this, stateMap);
    }
  }

  @override
  String toString() => "(${id ?? '_'}, substates:$substateIDs)";

  /// Finds the first transition matching all the criteria, or returns `null`.
  ///
  /// This passes the criteria to [Transition.matches].
  /// [event] An event name such as `turnOn`.
  /// [elapsedTime] A time value, as used in time-based transitions.
  /// [context] Used to evaluate [Transition.condition] to see if it should
  /// match. (If the condition is non-null and [ignoreContext] is not `true`)
  /// [ignoreContext] If `true`, skip the [Transition.condition] check.
  Transition<T>? transitionFor(
          {String? event,
          Duration? elapsedTime,
          T? context,
          bool? ignoreContext = false}) =>
      transitions.firstWhereOrNull((t) => t.matches(
          anEvent: event,
          elapsedTime: elapsedTime,
          context: context,
          ignoreContext: ignoreContext));

  /// The lowest node in the tree that encompasses all nodes.
  static State<T> commonSubtree<T>(Iterable<State<T>> nodes) => (nodes
      .map((s) => Set.of(s.ancestors()))
      .reduce((a, b) => a.intersection(b))
      .reduce((a, b) => a.order > b.order ? a : b));
}
