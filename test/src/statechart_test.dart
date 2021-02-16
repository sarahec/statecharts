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

import 'common/lightswitch.dart';

void main() {
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
}
