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
import 'package:built_value/built_value.dart';
import 'package:statecharts/statecharts.dart';

class Engine<T> {
  final RuntimeState<T> root;
  T? get context => _context;
  ExecutionStep<T> get currentStep => _currentStep;

  var _context;

  var _currentStep;

  // Iterable<RuntimeState<T>> _configuration = {};
  // var _statesToInvoke;

  // var _datamodel;
  // var _internalQueue;
  // var _externalQueue;
  // var _historyValue;
  // var _running;
  // var _binding;
  // var _historyValues;

  factory Engine(RootState<T> startNode, [T? context]) {
    assert(context == null || context is Built);
    final root = RuntimeState.wrapSubtree(startNode);
    final step0 = ExecutionStep.initial(root);
    return Engine._(root, context, step0);
  }

  Engine._(this.root, this._context, this._currentStep);

  // ExecutionContext<T> get executionContext => _executionContext;

  bool execute({String? anEvent, Duration? elapsedTime}) {
    // Get the available transitions

    final transitions = getTransitions(anEvent, elapsedTime, context);
    final step_n = nextStep(transitions);
    if (step_n.isUnchanged) return false;
    if (context != null) {
      var newContext = runTransitions(step_n, context);
      newContext = runExitStates(step_n, newContext);
      newContext = runExitStates(step_n, newContext);
      _context = newContext;
    }
    return true;
  }

  Iterable<RuntimeTransition<T>> getTransitions(
          String? anEvent, Duration? elapsedTime, T? context) =>
      [
        for (var s in _currentStep.activeStates)
          s.transitionFor(anEvent, elapsedTime, context)
      ].where((s) => s != null).cast();

  T? runTransitions(ExecutionStep<T> step, T? context) => context;

  T? runExitStates(ExecutionStep<T> step, T? context) {
    if (step.exitStates.isEmpty) return context;
    final builder = (context as Built).toBuilder();
    for (var s in step.exitStates) {
      s.exit(builder as T);
    }
    return builder.build();
  }

  T? runEntryStates(ExecutionStep<T> step, T? context) {
    if (step.entryStates.isEmpty) return context;
    final builder = (context as Built).toBuilder();
    for (var s in step.entryStates) {
      s.exit(builder as T);
    }
    return builder.build();
  }

  ExecutionStep<T> nextStep(Iterable<RuntimeTransition<T>> transitions) {
    final b = _currentStep.toBuilder();
    b.transitions = transitions;
    b.selections.removeAll(transitions.map((t) => t.source));
    b.selections.addAll(transitions.map((t) => t.targets).expand((s) => s));
    return b.build();
  }
}
