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

import '../lightswitch.dart';

void main() {
  group('lightswitch', () {
    Engine? engine;
    Lightbulb? bulb;

    setUp(() async {
      bulb = Lightbulb();
      engine = await Future.value(lightswitch)
          .then((ls) => Engine.initial<Lightbulb>(ls, bulb));
    });

    test('selects initial state', () {
      expect(engine!.currentStep.activeStates, containsAll([stateOff]));
    });

    test("executes 'on' transition", () async {
      await engine!.execute(anEvent: turnOn);
      expect(engine!.currentStep.activeStates, containsAll([stateOn]));
    });

    test('calls onEntry', () async {
      expect(bulb?.isOn, isFalse);
      await engine!.execute(anEvent: turnOn);
      expect(bulb?.isOn, isTrue);
      await engine!.execute(anEvent: turnOff);
      expect(bulb?.isOn, isFalse);
    });

    test('tests entry condition in transition', () async {
      final limit = 10;
      for (var i = 0; i < limit; i++) {
        await engine!.execute(anEvent: turnOn);
        await engine!.execute(anEvent: turnOff);
      }
      expect(engine!.context?.cycleCount, equals(limit));
    });
  });

  // group('basic statechart', () {
  //   // First example from https://statecharts.github.io/what-is-a-statechart.html

  //   final basic_composite = Statechart('D', [
  //     State('E', isInitial: true, substates: [
  //       State('G', transitions: [
  //         EventTransition('G', event: 'flick'),
  //         NonEventTransition('F', after: Duration(milliseconds: 500))
  //       ])
  //     ]),
  //     State('F')
  //   ]);

  //   Engine? engine;

  //   setUp(() {
  //     engine = Engine(basic_composite);
  //   });

  //   test('selects initial state', () {
  //     expect(engine!.activeStates.first.id, equals('E'));
  //   });

  //   // test('executes transitions', () {
  //   //   expect(engine.currentState.id, equals('off'));
  //   //   engine.execute(turnOn);
  //   //   expect(engine.currentState.id, equals('on'));
  //   //   engine.execute(turnOff);
  //   //   expect(engine.currentState.id, equals('off'));
  //   // });
  // });
}
