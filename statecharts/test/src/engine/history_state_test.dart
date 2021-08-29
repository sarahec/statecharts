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
import 'package:test/test.dart';

import '../examples/history.dart';

void main() {
  // We should be in state B initially plus its parents.
  test('default states', () {
    final engine = Engine<void>(history_statechart);
    expect(engine.currentStep.activeStates.map((s) => s.id!),
        containsAll(['root', 'A', 'B']));
  });

  // Trigger the history state without exiting `A`. This should
  // redirect to `C`.
  test('default history transition', () {
    final engine = Engine<void>(history_statechart);
    expect(engine.currentStep.activeStates.map((s) => s.id!),
        containsAll(['root', 'A', 'B']));
    engine.execute(anEvent: RESTORE);
    expect(engine.currentStep.activeStates.map((s) => s.id!),
        containsAll(['root', 'A', 'C']));
  });
}
