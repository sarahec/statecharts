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

import 'package:statecharts/src/engine/execution_step.dart';
import 'package:statecharts/statecharts.dart';
import 'package:test/test.dart';

import '../lightswitch.dart';

void main() {
  var step0;
  var tree;
  var rootState, onState, offState;

  setUp(() {
    tree = RuntimeState.wrapSubtree(lightswitch);
    step0 = ExecutionStep<Lightbulb>(tree);
    rootState = step0['lightswitch'];
    onState = step0['on'];
    offState = step0['off'];
  });
  group('ExecutionStep', () {
    test('defaults', () {
      expect(step0.root, equals(tree));
      expect(step0.activeStates, isEmpty);
      expect(step0.entryStates, isEmpty);
      expect(step0.exitStates, isEmpty);
    });
  });

  group('ExecutionStepBuilder', () {
    test('creation',
        () => expect(step0.toBuilder, isA<ExecutionStepBuilder<Lightbulb>>()));

    test('build w/o changes',
        () => expect(step0.toBuilder.build(), equals(step0)));

    test('initialization w/ idref', () {
      final step1 = step0.toBuilder..initialize(idrefs: ['on']);
      expect(step1.selections, equals([onState]));
      expect(step1.activeStates, containsAll([rootState, onState]));
      expect(step1.entryStates, containsAll([rootState, onState]));
      expect(step1.exitStates, isEmpty);
    });

    test('add leaf state', () {
      final step1 = step0.toBuilder
        ..add(onState)
        ..build();
      expect(step1.activeStates, equals([rootState, onState]));
      expect(step1.entryStates, equals([rootState, onState]));
      expect(step1.exitStates, isEmpty);
    });

    test('replace child state', () {
      final step1 = step0.toBuilder
        ..remove(onState)
        ..add(offState)
        ..build();
      expect(step1.activeStates, equals([rootState, offState]));
      expect(step1.entryStates, equals([rootState, offState]));
      expect(step1.exitStates, isEmpty);
    });
  });
}
