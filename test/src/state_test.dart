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

import 'package:test/test.dart';
import 'package:statecharts/statecharts.dart';

void main() {
  const turnOn = 'turnOn';
  const turnOff = 'turnOff';

  const transitionOn = Transition('on', event: turnOn);
  const transitionOff = Transition('off', event: turnOff);
  const lightswitch = StateMachine('lightswitch', [
    State('off', isInitial: true, transitions: [transitionOn]),
    State('on', transitions: [transitionOff]),
  ]);

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

    setUp(() {
      engine = Engine(lightswitch);
    });

    test('initial state', () => expect(engine.isInitialState, isTrue));

    test('execution', () {
      expect(engine.currentState.id, equals('off'));
      engine.execute(turnOn);
      expect(engine.currentState.id, equals('on'));
      engine.execute(turnOff);
      expect(engine.currentState.id, equals('off'));
    });
  });
}
