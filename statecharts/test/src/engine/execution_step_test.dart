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
import '../examples/history.dart';

void main() {
  group('with lightswitch', () {
    var step0;
    var root;
    var rootState, onState, offState;

    setUp(() async {
      root = await lightswitch;
      step0 = await ExecutionStep.initial<Lightbulb>(root);
      rootState = await root.find('lightswitch');
      onState = await root.find('on');
      offState = await root.find('off');
    });

    test('initialization', () {
      expect(step0.root, equals(root));
      expect(step0.activeStates, containsAll([rootState, offState]),
          reason: 'active states');
      expect(step0.entryStates, containsAll([rootState, offState]),
          reason: 'entry states');
      expect(step0.exitStates, isEmpty, reason: 'exit states');
    });

    group('modification', () {
      test('add leaf state', () {
        final step1 = step0.rebuild((b) => b
          ..selections.add(onState)
          ..priorStep = step0.toBuilder());
        expect(step1.activeStates, containsAll([rootState, onState]),
            reason: 'active states');
        expect(step1.entryStates, equals([onState]), reason: 'entry states');
        expect(step1.exitStates, equals([offState]), reason: 'exit states');
      });

      test('replace child state', () {
        final step1 = step0.rebuild((b) => b
          ..priorStep = step0.toBuilder()
          ..selections.remove(offState)
          ..selections.add(onState));
        expect(step1.activeStates, containsAll([rootState, onState]),
            reason: 'active states');
        expect(step1.entryStates, equals([onState]), reason: 'entry states');
        expect(step1.exitStates, equals([offState]), reason: 'exit states');
      });
    });
  });
  group('with history', () {
    ExecutionStep<void>? step0;
    State<void>? stateA,
        stateB,
        stateC,
        stateD,
        stateD1,
        stateD2,
        altState,
        stateA_AGAIN;

    setUp(() async {
      step0 = ExecutionStep.initial<void>(history_statechart);
      stateA = history_statechart.find('A');
      stateA_AGAIN = history_statechart.find('A_AGAIN');
      stateB = history_statechart.find('B')!;
      stateC = history_statechart.find('C')!;
      stateD = history_statechart.find('D')!;
      stateD1 = history_statechart.find('D1')!;
      stateD2 = history_statechart.find('D2')!;
      altState = history_statechart.find('ALT')!;
    });

    test('initialization', () {
      expect(step0!.root, equals(history_statechart));
      expect(step0!.activeStates,
          containsAll([history_statechart, stateA, stateB]),
          reason: 'active states');
      expect(
          step0!.entryStates, containsAll([history_statechart, stateA, stateB]),
          reason: 'entry states');
      expect(step0!.exitStates, isEmpty, reason: 'exit states');
      expect(step0!.historyValuesFor(stateA!), isEmpty);
    });

    test('replace child state', () {
      final step1 = step0!.rebuild((b) => b
        ..priorStep = step0!.toBuilder()
        ..selections.remove(stateB)
        ..selections.add(stateD!));
      expect(
          step1.activeStates, containsAll([history_statechart, stateA, stateD]),
          reason: 'active states');
      expect(step1.entryStates, equals([stateD, stateD1]),
          reason: 'entry states');
      expect(step1.exitStates, equals([stateB]), reason: 'exit states');
    });

    test('trigger history replacement (default)', () {
      final step1 = step0!.rebuild((b) => b
        ..priorStep = step0!.toBuilder()
        ..selections.remove(stateB)
        ..selections.add(stateA_AGAIN!));
      // A_AGAIN has a default transition to C
      expect(
          step1.activeStates, containsAll([history_statechart, stateA, stateC]),
          reason: 'active states');
      expect(step1.entryStates, equals([stateC]), reason: 'entry states');
      expect(step1.exitStates, equals([stateB]), reason: 'exit states');
    });
  });
}
