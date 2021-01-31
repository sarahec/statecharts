import 'package:mockito/mockito.dart';
/**
 * Copyright 2021 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import 'package:statecharts/statecharts.dart';
import 'package:test/test.dart';

class Lightbulb {
  int cycleCount = 0;
  bool? isOn;
  bool? wasOn;
  bool masterSwitch = false;
}

class MockBulb extends Mock implements Lightbulb {}

void main() {
  const turnOn = 'turnOn';
  const turnOff = 'turnOff';

  final transitionOn = Transition<Lightbulb>('on',
      condition: (b) => b.cycleCount < 10, event: turnOn);
  const transitionOff = Transition<Lightbulb>('off', event: turnOff);
  final lightswitch = StateMachine<Lightbulb>(
    'lightswitch',
    [
      State('off',
          isInitial: true,
          transitions: [transitionOn],
          onEntry: (b) => b.isOn = false,
          onExit: (b) => b.wasOn = false),
      State('on',
          transitions: [transitionOff],
          onEntry: (b) => b.isOn = true,
          onExit: (b) {
            b.wasOn = true;
            b.cycleCount += 1;
          })
    ],
    onEntry: (bulb) => bulb.masterSwitch = true,
  );

  group('lightswitch', () {
    test('initial state',
        () => expect(lightswitch.initialState.id, equals('off')));

    test('events',
        () => expect(lightswitch.events, containsAll([turnOn, turnOff])));

    test(
        'paths',
        () => expect(lightswitch.paths,
            containsAll(['lightswitch.turnOn', 'lightswitch.turnOff'])));

    test('transitions', () {
      expect(lightswitch.initialState.hasTransitionFor(event: turnOn), isTrue);
      expect(
          lightswitch.initialState.hasTransitionFor(event: turnOff), isFalse);
      expect(lightswitch.initialState.transitionFor(event: turnOn),
          equals(transitionOn));
    });
  });

  group('engine', () {
    var engine;
    var bulb;

    setUp(() {
      bulb = Lightbulb();
      engine = Engine(lightswitch, bulb)..enterInitialState();
    });

    test('before initial state', () {
      final mock = MockBulb();
      Engine(lightswitch, mock);
      verifyZeroInteractions(mock);
    });

    test('initial state', () {
      // Don't try to access the current state before calling `enterInitialState`
      // or you'll get a null check error. `setUp` called it for us
      expect(engine.currentState, isNotNull);
      expect(bulb.isOn, isFalse);
      expect(bulb.wasOn, isNull);
      expect(bulb.masterSwitch, isTrue);
    });

    test('switches states', () {
      expect(engine.currentState.id, equals('off'));
      engine.execute(turnOn);
      expect(engine.currentState.id, equals('on'));
      engine.execute(turnOff);
      expect(engine.currentState.id, equals('off'));
    });

    test('calls onEntry', () {
      expect(bulb.isOn, isFalse);
      engine.execute(turnOn);
      expect(bulb.isOn, isTrue);
      engine.execute(turnOff);
      expect(bulb.isOn, isFalse);
    });

    test('tests entry condition in transition', () {
      for (var i = 0; i < 15; i++) {
        engine.execute(turnOn);
        engine.execute(turnOff);
      }
      expect(engine.context?.cycleCount, equals(10));
    });
  });
}
