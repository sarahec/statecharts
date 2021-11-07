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

const skipReason = 'Complete unit testing before integration testing';
void main() {
  group('engine', () {
    group('initialization', () {
      test('uses default initial state', () {
        final bulb = Lightbulb();
        final engine = Engine<Lightbulb>(lightswitch, context: bulb);
        final tree = engine.currentStep.tree;
        expect(tree.activeStates.ids, equals(['lightswitch', 'off']));
        expect(tree.entryStates.ids, equals(['lightswitch', 'off']),
            reason: 'all initial states are entry states');
        expect(tree.exitStates, isEmpty, reason: 'no exit states');
      });

      test('uses initial transition', () {
        final switch2 = RootState<void>('switch',
            substates: [
              State<void>('off'),
              State<void>('on'),
            ],
            initialTransition: Transition<void>(targets: ['on']));
        final engine = Engine(switch2);
        final tree = engine.currentStep.tree;

        expect(tree.activeStates.ids, equals(['switch', 'on']));
        expect(tree.entryStates.ids, equals(['switch', 'on']));
        expect(tree.exitStates, isEmpty);
      });
    });

    group('execution', () {
      Engine? engine;
      Lightbulb? bulb;

      setUp(() {
        bulb = Lightbulb();
        engine = Engine<Lightbulb>(lightswitch, context: bulb);
      });

      test("executes 'on' transition", () {
        engine!.execute(anEvent: turnOn);
        final tree = engine!.currentStep.tree;
        expect(tree.activeStates.ids, equals(['lightswitch', 'on']),
            reason: 'off -> on');
        expect(tree.entryStates.ids, equals(['on']),
            reason: 'entering on state');
        expect(tree.exitStates.ids, equals(['off']),
            reason: 'exiting off state');
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
  });

  group('history', () {
    test('default states', () {
      final engine = Engine<void>(history_statechart);
      expect(
          engine.currentStep.tree.activeStates.ids, equals(['root', 'A', 'B']));
    });

    // Trigger the history state without exiting `A`. This should
    // redirect to `C`.
    test('default history transition', () {
      final engine = Engine<void>(history_statechart); // [root, A, B]
      engine.execute(anEvent: RESTORE_A);
      expect(
          engine.currentStep.tree.activeStates.ids, equals(['root', 'A', 'C']));
    });

    test('exit parent', () {
      final engine = Engine<void>(history_statechart); // [root, A, B]
      engine.execute(anEvent: EXIT);
      expect(engine.currentStep.tree.activeStates.ids,
          containsAllInOrder(['root', 'ALT']));
    });

    group('restores', () {
      test('leaf state', () {
        final engine = Engine<void>(history_statechart); // [root, A, B]
        engine.execute(anEvent: EXIT); // [root, ALT, ALT1]
        engine.execute(anEvent: RESTORE_A); // should remove ALT, add B
        expect(engine.currentStep.tree.activeStates.ids,
            equals(['root', 'A', 'B']));
      });

      test('deep state', () {
        final engine = Engine<void>(history_statechart);
        engine.execute(anEvent: DEEP);
        expect(engine.currentStep.tree.activeStates.ids,
            containsAll(['root', 'A', 'D', 'D2']));
        engine.execute(anEvent: EXIT);
        // make sure the active states are correct
        var stateIDs = engine.currentStep.tree.activeStates.ids;
        expect(stateIDs, contains('ALT'));
        expect(stateIDs, isNot(contains('A')), reason: 'in alt tree');
        // now execute the history state
        engine.execute(anEvent: RESTORE_A);
        // Match deep history
        expect(engine.currentStep.tree.activeStates.ids,
            containsAll(['root', 'A', 'D', 'D2']));
      });

      test('shallow state', () {
        final engine = Engine<void>(history_statechart);
        engine.execute(anEvent: EXIT);
        engine.execute(anEvent: DEEP);
        var stateIDs = engine.currentStep.tree.activeStates.ids;
        expect(stateIDs, contains('ALT2b'));
        expect(stateIDs, isNot(contains('A')), reason: 'in alt tree');
        // engine.execute(anEvent: EXIT);
        // engine.execute(anEvent: RESTORE_A);
        // // Match deep history
        // expect(engine.currentStep.activeStates.ids,
        //     containsAll(['root', 'A', 'D', 'D2']));
      });
    });
  }, skip: skipReason);

  group('composite', () {
    // First example from https://statecharts.github.io/what-is-a-statechart.html

    final basicComposite = RootState<void>(
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
      final engine = Engine<void>(basicComposite);
      expect(engine.currentStep.tree.activeStates.ids,
          containsAll(['D', 'E', 'G']));
      expect(engine.currentStep.tree.activeStates.first.id, equals('D'));
    });

    test('timed transition', () {
      final engine = Engine<void>(basicComposite);
      engine.execute(anEvent: 'flick'); // self transition
      expect(engine.currentStep.tree.activeStates.ids, equals(['D', 'E', 'G']));
      engine.execute(elapsedTime: Duration(milliseconds: 250));
      expect(engine.currentStep.tree.activeStates.ids, equals(['D', 'E', 'G']),
          reason: 'before time');
      engine.execute(elapsedTime: Duration(milliseconds: 500));
      expect(engine.currentStep.tree.activeStates.ids, equals(['D', 'F']),
          reason: 'after timed transition');
    });

    test('timed transition, late', () {
      final engine = Engine<void>(basicComposite);
      // Should still trigger
      engine.execute(elapsedTime: Duration(milliseconds: 750));
      expect(engine.currentStep.tree.activeStates.ids, containsAll(['D', 'F']),
          reason: 'after timed transition');
    });
  });
}
