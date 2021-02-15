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

import 'common/lightswitch.dart';

void main() {
  var engine;
  var bulb;
  setUp(() {
    bulb = Lightbulb();
    engine = Engine(lightswitch, bulb);
  });

  test('initial state', () {
    expect(engine.currentState, equals(stateOff));
  });

  test('switches states', () {
    engine.enterInitialState();
    expect(engine.currentState.id, equals('off'));
    engine.execute(turnOn);
    expect(engine.currentState.id, equals('on'));
    engine.execute(turnOff);
    expect(engine.currentState.id, equals('off'));
  });

  test('calls onEntry', () {
    engine.enterInitialState();
    expect(bulb.isOn, isFalse);
    engine.execute(turnOn);
    expect(bulb.isOn, isTrue);
    engine.execute(turnOff);
    expect(bulb.isOn, isFalse);
  });

  test('tests entry condition in transition', () {
    engine.enterInitialState();
    for (var i = 0; i < 15; i++) {
      engine.execute(turnOn);
      engine.execute(turnOff);
    }
    expect(engine.context?.cycleCount, equals(10));
  });
}
