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

import 'package:meta/meta.dart';
import 'package:statecharts/statecharts.dart';

/// Steps through the statechart, calling the [State.onEntry] and [State.onExit]
/// methods to alter the data in the [context].
///
/// Usage:
/// 1. Create a state machine (here called `Lightswitch`) and its data context
/// (`lightbulb`).
/// 2. Initialize the engine, then feed it events and timestamps.
///
/// ```
/// final lightswitch = RootState<Lightbulb>(
///    'lightswitch', [stateOff, stateOn]);
///
/// final engine = Engine(ls, bulb));
/// // Execute an event
/// engine.execute(anEvent: 'turnOn');
/// ```
class Engine<T> implements EngineCallback {
  /// The root of the tree (statechart).
  final RootState<T> root;

  ExecutionStep<T> _currentStep;

  /// Creates an engine.
  ///
  /// [root] The [RootState].
  /// [context] The data object.
  /// [step] The current step. If unspecified, creates a new, initial step.
  Engine(RootState<T> root, {T? context, ExecutionStep<T>? step})
      // ignore: prefer_initializing_formals
      : root = root,
        _currentStep = step ?? ExecutionStep(root, context, History(root)) {
    if (step == null) initialize();
  }

  EngineCallback get callback => this;

  /// The data this engine is managing.
  T? get context => _currentStep.context;

  /// Current execution state (immutable).
  ExecutionStep<T> get currentStep => _currentStep;

  /// Override if the context implements the builder pattern.
  ///
  /// This takes a context builder and returns a new context with the changes.
  /// Default implementation is a no-op.
  T? buildContext(dynamic builder) => builder;

  /// Override if the context implements the builder pattern.
  ///
  /// This should return a builder for the context.
  /// Default implementation is a no-op.
  dynamic contextToBuilder(T? context) => context;

  /// Finds and executes transitions matching the given conditions, returning
  /// `true` if anything matched.
  ///
  /// May execute additional transitions where [Transition.condition] matches.
  ///
  /// [anEvent] The event name to match.
  /// [elapsedTime] The time to match.
  bool execute({String? anEvent, Duration? elapsedTime}) {
    final transitions = getTransitions(_currentStep, anEvent, elapsedTime);
    _currentStep = executeTransitions(transitions);
    return transitions.isNotEmpty;
  }

  /// Runs all the transitions in order. Rerturns an updated [ExecutionStep].
  ///
  /// Note: this opens a builder for the context, [ExecutionStep], and
  /// (indirectly) [History]. These are all rebuilt after applying changes.
  ///
  /// [transitions] list of transitions to execute. Should not be empty.
  ///
  @visibleForOverriding
  ExecutionStep<T> executeTransitions(Iterable<Transition<T>> transitions) {
    if (transitions.isEmpty) return _currentStep;

    final builder = currentStep.toBuilder();
    final ctx = contextToBuilder(currentStep.context);

    builder.applyTransitions(transitions);

    // exit old
    for (var s in builder.statesToExit) {
      if (s.containsHistoryState) {
        builder.saveHistory(s);
      }
      s.exit(context, callback);
    }

    // enter new
    for (var s in builder.statesToEnter) {
      s.enter(context, callback);
      if (builder.statesForDefaultEntry.contains(s) &&
          s.initialTransition?.action != null) {
        s.initialTransition?.action!(context, callback);
      }
    }

    // perform transition actions
    for (var t in transitions) {
      if (t.action != null) t.action!(context, callback);
    }

    return builder.build(
      buildContext(ctx),
    );
  }

  /// All targets of 'transition' after replacing any history states.
  @visibleForOverriding
  Set<State<T>> getEffectiveTargetStates(transition, History<T> history) {
    var targets = <State<T>>{};
    for (var s in transition.targetStates) {
      if (s is HistoryState<T>) {
        if (history.contains(s)) {
          targets.addAll(Set.of(history[s]!));
        } else {
          targets.addAll(getEffectiveTargetStates(s.transition, history));
        }
      } else {
        targets.add(s);
      }
    }
    return targets;
  }

  /// The smallest possible subtree containing all the transition targets.
  @visibleForOverriding
  State<T>? getTransitionDomain(Transition<T> t, History<T> history) {
    final tstates = getEffectiveTargetStates(t, history);
    if (tstates.isEmpty) {
      return null;
    }
    if (t.type == TransitionType.internalTransition &&
        t.source!.isCompound &&
        tstates.every((s) => s.descendsFrom(t.source!))) {
      return t.source;
    }
    return State.commonSubtree([t.source!, ...tstates]);
  }

  /// Locates the transitions used by [execute].
  @visibleForOverriding
  Iterable<Transition<T>> getTransitions(
          ExecutionStep<T> step, String? anEvent, Duration? elapsedTime) =>
      [
        // TODO determine when we should filter for atomic states per the spec
        for (var s in step.activeStates) // removing: .where((s) => s.isAtomic))
          s.transitionFor(
              event: anEvent, elapsedTime: elapsedTime, context: step.context)
      ].where((t) => t != null).cast<Transition<T>>();

  /// Loads the initial states based on `root.initialTransition` or the first
  /// child of the root.
  void initialize() {
    final initialTransition =
        root.initialTransition ?? NonEventTransition.toDefaultState(root);
    _currentStep = executeTransitions([initialTransition]);
  }
}
