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
/// final engine = Engine.initial<Lightbulb>(ls, bulb));
/// // Execute an event
/// await engine.execute(anEvent: 'turnOn');
/// ```
class Engine<T> {
  /// The root of the tree (statechart).
  final RootState<T> root;

  T? _context;
  ExecutionStep<T> _currentStep;

  /// Passed to [Transition.action], [State.onEntry], and [State.onExit].
  final EngineCallback? callback;

  /// Creates an engine.
  ///
  /// [root] The [RootState].
  /// [context] The data object.
  /// [step] The current step. If unspecified, creates a new, initial step.
  /// [callback] Signaling mechanism back to the engine.
  Engine(this.root, {T? context, ExecutionStep<T>? step, this.callback})
      : _context = context,
        _currentStep = ExecutionStepBase(root);

  /// The data this engine is managing.
  T? get context => _context;

  /// Current execution state.
  ExecutionStep<T> get currentStep => _currentStep;

  /// Runs transitions, [State.onEntry], and [State.onExit] for the current context.
  @visibleForOverriding
  T? applyChanges(ExecutionStep<T> step, T? context) {
    runTransitions(step.transitions ?? [], context, callback);
    runExitStates(step, context, callback);
    runEntryStates(step, context, callback);
    return context;
  }

  /// Executes the matching transitions, returning `true` if anything changes.
  ///
  /// May execute additional transitions where [Transition.condition] matches.
  ///
  /// [anEvent] The event name to match.
  /// [elapsedTime] The time to match.
  bool execute({String? anEvent, Duration? elapsedTime}) {
    final transitions =
        getTransitions(_currentStep, anEvent, elapsedTime, _context);
    final step_n = nextStep(_currentStep, transitions);
    if (step_n.isChanged) {
      _context = applyChanges(step_n, _context);
      _currentStep = step_n;
    }
    return step_n.isChanged;
  }

  /// Locates the transactions used by [execute].
  @visibleForOverriding
  Iterable<Transition<T>> getTransitions(ExecutionStep<T> step, String? anEvent,
          Duration? elapsedTime, T? context) =>
      [
        for (var s in step.activeStates)
          s.transitionFor(
              event: anEvent, elapsedTime: elapsedTime, context: context)
      ].where((t) => t != null).cast<Transition<T>>();

  /// Calculates the next step from the previous step and identified transitions.
  @visibleForOverriding
  ExecutionStep<T> nextStep(
          ExecutionStep<T> step, Iterable<Transition<T>> transitions) =>
      step.applyTransitions(transitions);

  /// Calls [State.onEntry] on the step's entry states.
  @visibleForOverriding
  void runEntryStates(ExecutionStep<T> step, T? context,
      [EngineCallback? callback]) {
    for (var s in step.entryStates) {
      s.enter(context);
    }
  }

  /// Calls [State.onExit] on the step's exit states.
  @visibleForOverriding
  void runExitStates(ExecutionStep<T> step, T? context,
      [EngineCallback? callback]) {
    for (var s in step.exitStates) {
      s.exit(context);
    }
  }

  /// Runs [Transition.action] for the selected transitions.
  @visibleForOverriding
  void runTransitions(Iterable<Transition<T>> transitions, T? context,
      [EngineCallback? callback]) {
    for (var t in transitions) {
      if (t.action != null) t.action!(context, callback);
    }
  }
}
