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
// ignore_for_file: constant_identifier_names

import 'package:statecharts/statecharts.dart';
import 'package:test/test.dart';

import '../examples/history.dart';

const IntegrationTest = 'Integration test';

void main() {
  test('initial state', () {
    final engine = Engine<void>(history_statechart);
    expect(engine.currentStep.activeStates.ids, equals(['A', 'B']));
  });

  // Trigger the history state without exiting `A`. This should
  // redirect to `C`.
  test('default history transition', () {
    final engine = Engine<void>(history_statechart); // [root, A, B]
    engine.execute(anEvent: RESTORE_A);
    expect(engine.currentStep.activeStates.ids, equals(['A', 'C']));
  });

  test('records history on exit', () {
    final engine = Engine<void>(history_statechart);
    engine.execute(anEvent: EXIT);
    expect(engine.currentStep.activeStates.ids, equals(['ALT', 'ALT1']));
    expect(engine.currentStep.history.find('A')?.ids, equals(['B']));
  });

  group('restores', () {
    test('default', () {
      final engine = Engine<void>(history_statechart); // [A, B]
      engine.execute(
          anEvent: RESTORE_A); // change B to C  from default transi9tion
      expect(engine.currentStep.activeStates.ids, equals(['A', 'C']),
          reason: 'C is the default if none recorded');
    });

    test('leaf state', () {
      final engine = Engine<void>(history_statechart); // [A, B]
      engine.execute(anEvent: EXIT); // [ALT, ALT1]
      engine.execute(anEvent: RESTORE_A); // should remove ALT, restore A, B
      expect(engine.currentStep.activeStates.ids, equals(['A', 'B']),
          reason: 'B was active at exit');
    });

    test('deep state', () {
      final engine = Engine<void>(history_statechart);
      engine.execute(anEvent: DEEP);
      expect(
          engine.currentStep.activeStates.ids, containsAll(['A', 'D', 'D2']));
      engine.execute(anEvent: EXIT);
      // make sure the active states are correct
      var stateIDs = engine.currentStep.activeStates.ids;
      expect(stateIDs, contains('ALT'));
      expect(stateIDs, isNot(contains('A')), reason: 'in alt tree');
      // now execute the history state
      engine.execute(anEvent: RESTORE_A);
      // Match deep history
      expect(
          engine.currentStep.activeStates.ids, containsAll(['A', 'D', 'D2']));
    });

    test('shallow state', () {
      final engine = Engine<void>(history_statechart);
      engine.execute(anEvent: EXIT);
      engine.execute(anEvent: RESTORE_ALT);
      expect(engine.currentStep.activeStates.ids, equals(['A', 'E']));
    });
  });
}
