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
    final planner = TreeUpdatePlanner(root);
    expect(planner.activeStates, isEmpty);
    expect(planner.statesToEnter, isEmpty);
    expect(planner.statesForDefaultEntry, isEmpty);
    expect(planner.statesToExit, isEmpty);
  });

  test('computeEntrySet', () {
    final planner = TreeUpdatePlanner(countedLightswitch);
    planner.computeEntrySet([countedLightswitch.initialTransition!]);
    expect(planner.activeStates, isEmpty);
    expect(planner.statesToEnter.ids, equals(['off']));
    expect(planner.statesForDefaultEntry.ids, isEmpty);
    expect(planner.statesToExit, isEmpty, reason: 'no exit states');
  });

  test('selects ancestors', () {
    final planner = TreeUpdatePlanner(lightswitch);
    planner.addAncestorStatesToEnter(lightswitch.find('off')!);
    expect(planner.activeStates.ids, isEmpty); // no prior states
    expect(planner.statesToEnter.ids, equals(['lightswitch']));
    expect(planner.statesForDefaultEntry.ids, isEmpty);
    expect(planner.statesToExit, isEmpty);
  });

  test('selects leaf', () {
    final planner = TreeUpdatePlanner(lightswitch);
    planner.addDescendantStatesToEnter(lightswitch.find('off')!);
    expect(planner.activeStates.ids, isEmpty); // no prior states
    expect(planner.statesToEnter.ids, equals(['off']));
    expect(planner.statesForDefaultEntry.ids, isEmpty);
    expect(planner.statesToExit, isEmpty);
  });

  test('selects default states', () {
    final planner = TreeUpdatePlanner(lightswitch);
    planner.addDescendantStatesToEnter(lightswitch);
    expect(planner.activeStates.ids, isEmpty); // no prior states
    expect(planner.statesToEnter.ids, equals(['lightswitch', 'off']));
    expect(planner.statesForDefaultEntry.ids, equals(['lightswitch']));
    expect(planner.statesToExit, isEmpty);
  });

  test('selects parallel children', () {
    final tree = RootState('root', substates: [
      State(
        'a',
        isParallel: true,
        substates: [State('a1'), State('a2')],
      ),
    ]);
    final planner = TreeUpdatePlanner(tree);
    expect(planner.statesToEnter, isEmpty);
    planner.addDescendantStatesToEnter(tree);
    expect(planner.activeStates.ids, isEmpty); // no prior states
    expect(planner.statesToEnter.ids, equals(['root', 'a', 'a1', 'a2']));
    expect(planner.statesForDefaultEntry.ids, equals(['root']));
    expect(planner.statesToExit, isEmpty);
  });

  test('selects parallel children of ancestor', () {
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
    final planner = TreeUpdatePlanner(tree);
    expect(planner.statesToEnter, isEmpty);
    planner.addAncestorStatesToEnter(tree.find('a21')!);
    expect(planner.activeStates.ids, isEmpty); // no prior states
    expect(planner.statesToEnter.ids, equals(['root', 'a', 'a1', 'a2', 'a21']));
    expect(planner.statesForDefaultEntry.ids, equals(['a2']));
    expect(planner.statesToExit, isEmpty);
  });
}
