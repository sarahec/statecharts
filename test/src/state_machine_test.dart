// ignore_for_file: slash_for_doc_comments

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
import 'package:statecharts/src/statechart.dart';
import 'package:statecharts/statecharts.dart';
import 'package:test/test.dart';

import 'common/lightswitch.dart';

void main() {
  test('explicit initial state',
      () => expect(lightswitch.initialState.id, equals('off')));

  test('implicit initial state', () {
    final singularity = Statechart('singularity', [State('one')]);
    expect(singularity.initialState.id, equals('one'));
  });

  test('all atomic',
      () => expect(lightswitch.states.every((s) => s.isAtomic), isTrue));

  test('events',
      () => expect(lightswitch.events, containsAll([turnOn, turnOff])));

  test('transitions', () {
    expect(lightswitch.initialState.hasTransitionFor(event: turnOn), isTrue);
    expect(lightswitch.initialState.hasTransitionFor(event: turnOff), isFalse);
    expect(
        lightswitch.initialState
            .transitionFor(event: turnOn, ignoreContext: true),
        equals(transitionOn));
  });
}
