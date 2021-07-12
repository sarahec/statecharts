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

import 'package:statecharts/statecharts.dart';

class Engine<T> {
  final RootState<T> root;
  T? _context;
  ExecutionStep<T> _currentStep;

  Engine(this.root, this._context, this._currentStep);

  static Future<Engine<T>> initial<T>(RootState<T> root, T? context) async {
    final step0 = await ExecutionStep.initial<T>(root);
    return Engine(root, context, step0);
  }

  T? get context => _context;

  ExecutionStep<T> get currentStep => _currentStep;

  T? applyChanges(ExecutionStep<T> step, T? context) {
    runTransitions(step, context);
    runExitStates(step, context);
    runEntryStates(step, context);
    return context;
  }

  Future<bool> execute({String? anEvent, Duration? elapsedTime}) async {
    final transitions =
        await getTransitions(_currentStep, anEvent, elapsedTime, _context);
    final step_n = nextStep(_currentStep, transitions);
    if (step_n.isChanged) {
      _context = applyChanges(step_n, _context);
      _currentStep = step_n;
    }
    return step_n.isChanged;
  }

  Future<Iterable<Transition<T>>> getTransitions(ExecutionStep<T> step,
          String? anEvent, Duration? elapsedTime, T? context) async =>
      [
        for (var s in step.activeStates)
          await s.transitionFor(
              event: anEvent, elapsedTime: elapsedTime, context: context)
      ].where((t) => t != null).cast<Transition<T>>();

  ExecutionStep<T> nextStep(
      ExecutionStep<T> step, Iterable<Transition<T>> transitions) {
    final b = step.toBuilder();
    b.priorStep = step.toBuilder();
    b.transitions = transitions;
    b.selections.removeAll(transitions.map((t) => t.source));
    b.selections.addAll(transitions.map((t) => t.targets).expand((s) => s));
    return b.build();
  }

  void runEntryStates(ExecutionStep<T> step, T? context) {
    for (var s in step.entryStates) {
      s.enter(context);
    }
  }

  void runExitStates(ExecutionStep<T> step, T? context) {
    for (var s in step.exitStates) {
      s.exit(context);
    }
  }

  // TODO Implement runTransitions
  void runTransitions(ExecutionStep<T> step, T? context) => context;
}
