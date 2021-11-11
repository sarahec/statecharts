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

import '../examples/lightswitch.dart';

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
