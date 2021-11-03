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
// import '../examples/history.dart';

void main() {
  test('initial states (default)', () {
    final tree = StateTree(lightswitch);

    expect(tree.activeStates.ids, equals(['lightswitch']));
    expect(tree.entryStates.ids, equals(['lightswitch']));
    expect(tree.exitStates, isEmpty);
  });

  test('initial transition', () {
    final switch2 = RootState<void>('switch',
        substates: [
          State<void>('off'),
          State<void>('on'),
        ],
        initialTransition: Transition<void>(targets: ['on']));
    final tree2 = StateTree(switch2);

    expect(tree2.activeStates.ids, equals(['switch', 'on']));
    expect(tree2.entryStates.ids, equals(['switch', 'on']));
    expect(tree2.exitStates, isEmpty);
  }, skip: 'Move to engine test');

  test('find', () {
    final tree = StateTree(lightswitch);

    expect(tree.find('off')?.id, equals('off'));
  });

  test('toBuilder()', () {
    final tree = StateTree(lightswitch);
    final b = tree.toBuilder();
    expect(b, isNot(same(tree)));
  });

  test('build()', () {
    final tree = StateTree(lightswitch);
    final b = tree.toBuilder();
    // rebuild without changes
    expect(b.build().activeStates, equals(tree.activeStates));
  });

  test('switch', () {
    final b = StateTree(lightswitch).toBuilder();
    b.deselect(b.find('off')!);
    b.deselect(b.find('on')!);
    final tree = b.build();
    expect(tree.activeStates.ids, equals(['lightswitch', 'on']));
    expect(tree.entryStates.ids, equals(['on']));
    expect(tree.exitStates.ids, equals(['off']));
  }, skip: 'Move to engine test');

// TODO test select(all:)
// TODO test deselect(all:)

  // test('switch states', () {
  //   final b = tree!.toBuilder();
  //   b.removeSubtree(b.find('off')!);
  //   b.addState(b.find('on')!);
  //   expect(b.activeStates.ids, equals(['lightswitch', 'on']));
  //   expect(b.entryStates.ids, equals(['on']));
  //   expect(b.exitStates.ids, equals(['off']));
  // }, skip: true);
}
