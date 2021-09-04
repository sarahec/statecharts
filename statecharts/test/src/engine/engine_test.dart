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
import '../examples/lightswitch.dart';

void main() {
  group('lightswitch', () {
    Engine? engine;
    Lightbulb? bulb;

    setUp(() {
      bulb = Lightbulb();
      engine = Engine<Lightbulb>(lightswitch, context: bulb);
    });

    test('selects initial state', () {
      expect(engine!.currentStep.activeStates.sorted,
          equals([lightswitch, stateOff]));
    });

    test("executes 'on' transition", () {
      engine!.execute(anEvent: turnOn);
      expect(engine!.currentStep.activeStates.sorted,
          equals([lightswitch, stateOn]));
    });

    test('calls onEntry', () {
      expect(bulb?.isOn, isFalse);
      engine!.execute(anEvent: turnOn);
      expect(bulb?.isOn, isTrue);
      engine!.execute(anEvent: turnOff);
      expect(bulb?.isOn, isFalse);
    });

    test('tests entry condition in transition', () {
      final limit = 10;
      for (var i = 0; i < limit; i++) {
        engine!.execute(anEvent: turnOn);
        engine!.execute(anEvent: turnOff);
      }
      expect(engine!.context?.cycleCount, equals(limit));
    });
  });

  group('history', () {
    test('default states', () {
      final engine = Engine<void>(history_statechart);
      expect(engine.currentStep.activeStates.ids, equals(['root', 'A', 'B']));
    });

    // Trigger the history state without exiting `A`. This should
    // redirect to `C`.
    test('default history transition', () {
      final engine = Engine<void>(history_statechart); // [root, A, B]
      engine.execute(anEvent: RESTORE_A);
      expect(engine.currentStep.activeStates.ids, equals(['root', 'A', 'C']));
    });

    test('exit parent', () {
      final engine = Engine<void>(history_statechart); // [root, A, B]
      engine.execute(anEvent: EXIT);
      expect(engine.currentStep.activeStates.ids,
          containsAllInOrder(['root', 'ALT']));
    });

    group('restores', () {
      test('leaf state', () {
        final engine = Engine<void>(history_statechart); // [root, A, B]
        engine.execute(anEvent: EXIT); // [root, ALT, ALT1]
        engine.execute(anEvent: RESTORE_A); // should remove ALT, add B
        expect(engine.currentStep.activeStates.ids, equals(['root', 'A', 'B']));
      });

      test('deep state', () {
        final engine = Engine<void>(history_statechart);
        engine.execute(anEvent: DEEP);
        expect(engine.currentStep.activeStates.ids,
            containsAll(['root', 'A', 'D', 'D2']));
        engine.execute(anEvent: EXIT);
        // make sure the active states are correct
        var stateIDs = engine.currentStep.activeStates.ids;
        expect(stateIDs, contains('ALT'));
        expect(stateIDs, isNot(contains('A')), reason: 'in alt tree');
        // now execute the history state
        engine.execute(anEvent: RESTORE_A);
        // Match deep history
        expect(engine.currentStep.activeStates.ids,
            containsAll(['root', 'A', 'D', 'D2']));
      }, skip: true);

      test('shallow state', () {
        final engine = Engine<void>(history_statechart);
        engine.execute(anEvent: EXIT);
        engine.execute(anEvent: DEEP);
        var stateIDs = engine.currentStep.activeStates.ids;
        expect(stateIDs, contains('ALT2b'));
        expect(stateIDs, isNot(contains('A')), reason: 'in alt tree');
        // engine.execute(anEvent: EXIT);
        // engine.execute(anEvent: RESTORE_A);
        // // Match deep history
        // expect(engine.currentStep.activeStates.ids,
        //     containsAll(['root', 'A', 'D', 'D2']));
      });
    });
  });

  group('composite', () {
    // First example from https://statecharts.github.io/what-is-a-statechart.html

    final basic_composite = RootState<void>(
      'D',
      substates: [
        State('E', substates: [
          State('G', transitions: [
            EventTransition(targets: ['G'], event: 'flick'),
            NonEventTransition(
                targets: ['F'], after: Duration(milliseconds: 500))
          ])
        ]),
        State('F')
      ],
      initialTransition: Transition(targets: ['E']),
    );

    test('default initial state', () {
      final engine = Engine<void>(basic_composite);
      expect(engine.currentStep.activeStates.ids, containsAll(['D', 'E', 'G']));
      expect(engine.currentStep.activeStates.first.id, equals('E'));
    });

    test('timed transition', () {
      final engine = Engine<void>(basic_composite);
      engine.execute(anEvent: 'flick'); // self transition
      expect(engine.currentStep.activeStates.ids, equals(['D', 'E', 'G']));
      engine.execute(elapsedTime: Duration(milliseconds: 250));
      expect(engine.currentStep.activeStates.ids, equals(['D', 'E', 'G']),
          reason: 'before time');
      engine.execute(elapsedTime: Duration(milliseconds: 500));
      expect(engine.currentStep.activeStates.ids, equals(['D', 'F']),
          reason: 'after timed transition');
    });

    test('timed transition, late', () {
      final engine = Engine<void>(basic_composite);
      // Should still trigger
      engine.execute(elapsedTime: Duration(milliseconds: 750));
      expect(engine.currentStep.activeStates.ids, containsAll(['D', 'F']),
          reason: 'after timed transition');
    });
  });
}

/// Testing utility
extension IDs<T> on Iterable<State<T>> {
  /// The [id] values of all states sorted by [order]
  Iterable<String> get ids => [for (var s in sorted) s.id ?? '_'];

  Iterable<State<T>> get sorted =>
      (toList()..sort((a, b) => a.order.compareTo(b.order)));
}
