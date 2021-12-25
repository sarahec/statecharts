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

import 'package:test/test.dart';
import 'package:statecharts/statecharts.dart';

import '../examples/lightswitch.dart';

void main() {
  test('initial values', () async {
    final root = lightswitch;
    final builder = ExecutionStep(root, null, History(root)).toBuilder();
    expect(builder.activeStates, isEmpty);
    expect(builder.statesToEnter, isEmpty);
    expect(builder.statesForDefaultEntry, isEmpty);
    expect(builder.statesToExit, isEmpty);
  });

  group('selects', () {
    test('ancestors', () {
      final builder =
          ExecutionStep(lightswitch, null, History(countedLightswitch))
              .toBuilder();
      builder.addAncestorStatesToEnter(lightswitch.find('off')!);
      expect(builder.activeStates.ids, isEmpty); // no prior states
      expect(builder.statesToEnter.ids, isEmpty);
      expect(builder.statesForDefaultEntry.ids, isEmpty);
      expect(builder.statesToExit, isEmpty);
    });

    test('leaf', () {
      final builder =
          ExecutionStep(lightswitch, null, History(lightswitch)).toBuilder();
      builder.addDescendantStatesToEnter(lightswitch.find('off')!);
      expect(builder.activeStates.ids, isEmpty); // no prior states
      expect(builder.statesToEnter.ids, equals(['off']));
      expect(builder.statesForDefaultEntry.ids, isEmpty);
      expect(builder.statesToExit, isEmpty);
    });

    test('default states', () {
      final builder =
          ExecutionStep(lightswitch, null, History(lightswitch)).toBuilder();
      builder.addDescendantStatesToEnter(lightswitch);
      expect(builder.activeStates.ids, isEmpty); // no prior states
      expect(builder.statesToEnter.ids, equals(['lightswitch', 'off']));
      expect(builder.statesForDefaultEntry.ids, equals(['lightswitch']));
      expect(builder.statesToExit, isEmpty);
    });

    test('parallel children', () {
      final tree = RootState('root', substates: [
        State(
          'a',
          isParallel: true,
          substates: [State('a1'), State('a2')],
        ),
      ]);
      final builder = ExecutionStep(tree, null, History(tree)).toBuilder();
      expect(builder.statesToEnter, isEmpty);
      builder.addDescendantStatesToEnter(tree);
      expect(builder.activeStates.ids, isEmpty); // no prior states
      expect(builder.statesToEnter.ids, equals(['root', 'a', 'a1', 'a2']));
      expect(builder.statesForDefaultEntry.ids, equals(['root']));
      expect(builder.statesToExit, isEmpty);
    });

    test('parallel children of ancestor', () {
      final tree = RootState('root', substates: [
        State(
          'a',
          isParallel: true,
          substates: [
            State('a1'),
            State('a2', substates: [State('a21')])
          ],
        ),
      ]);
      final builder = ExecutionStep(tree, null, History(tree)).toBuilder();
      expect(builder.statesToEnter, isEmpty);
      builder.addAncestorStatesToEnter(tree.find('a21')!);
      expect(builder.activeStates.ids, isEmpty); // no prior states
      expect(builder.statesToEnter.ids, equals(['a', 'a1', 'a2', 'a21']));
      expect(builder.statesForDefaultEntry.ids, equals(['a2']));
      expect(builder.statesToExit, isEmpty);
    });
  });

  group('Entry and exit', () {
    test('computeEntrySet', () {
      final builder =
          ExecutionStep(countedLightswitch, null, History(countedLightswitch))
              .toBuilder();
      builder.computeEntrySet([countedLightswitch.initialTransition!]);
      expect(builder.activeStates, isEmpty);
      expect(builder.statesToEnter.ids, equals(['off']));
      expect(builder.statesForDefaultEntry.ids, isEmpty);
      expect(builder.statesToExit, isEmpty, reason: 'no exit states');
    });

    test('computeExitSet', () {
      final offState = countedLightswitch.find('off')!;
      final onTransition = offState.transitions.single;
      final builder = ExecutionStep(
          countedLightswitch, null, History(countedLightswitch),
          activeStates: [offState]).toBuilder();

      builder.computeExitSet([onTransition]);
      expect(builder.statesToExit, containsAll([offState]));
    });
  });
}
