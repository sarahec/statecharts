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
  group('ExecutionStep', () {
    test('initialization w/ defaults', () {
      expect(step0.root, equals(root));
      expect(step0.activeStates, containsAll([rootState, offState]),
          reason: 'active states');
      expect(step0.entryStates, containsAll([rootState, offState]),
          reason: 'entry states');
      expect(step0.exitStates, isEmpty, reason: 'exit states');
    });

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
}
