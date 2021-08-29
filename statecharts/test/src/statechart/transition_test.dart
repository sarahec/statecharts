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

void main() {
  group('event transition', () {
    final eventTransition = EventTransition<int>(targets: ['a'], event: 'onA');

    test('matches event',
        () => expect(eventTransition.matches(anEvent: 'onA'), isTrue));

    test(
        'matches event, any context',
        () => expect(
            eventTransition.matches(anEvent: 'onA', context: 1), isTrue));

    test('doesn\'t match wrong event',
        () => expect(eventTransition.matches(anEvent: 'onB'), isFalse));

    test(
        '== matching transition',
        () => expect(eventTransition,
            equals(EventTransition<int>(targets: ['a'], event: 'onA'))));
    test(
        '!= mismatched transition',
        () => expect(eventTransition,
            isNot(equals(EventTransition<int>(targets: ['b'], event: 'onB')))));
  });

  group('event transition + condition', () {
    final cond = State<int>('cond');

    final conditionalTransition = EventTransition<int>(
        targets: ['cond'], event: 'onA', condition: (int c) => c == 0);

    test(
        'matches event and condition',
        () => expect(
            conditionalTransition.matches(anEvent: 'onA', context: 0), isTrue));

    test(
        'doesn\'t match correct event, wrong condition',
        () => expect(conditionalTransition.matches(anEvent: 'onA', context: 1),
            isFalse));
    test(
        'doesn\'t match wrong event, correct condition',
        () => expect(conditionalTransition.matches(anEvent: 'onB', context: 0),
            isFalse));

    test('doesn\'t match correct event, missing context',
        () => expect(conditionalTransition.matches(anEvent: 'onA'), isFalse));
  });

  group('non-event transition', () {
    test('matches on condition', () {
      final conditionalTransition = NonEventTransition<int>(
          targets: ['cond'], condition: (int c) => c == 0);
      expect(conditionalTransition.matches(context: 0), isTrue);
      expect(conditionalTransition.matches(context: 1), isFalse);
    });

    test('matches on delay', () {
      final conditionalTransition = NonEventTransition<int>(
          targets: ['cond'], after: Duration(minutes: 1));
      expect(conditionalTransition.matches(elapsedTime: Duration(minutes: 1)),
          isTrue);
      expect(
          conditionalTransition.matches(
              elapsedTime: Duration(milliseconds: 500)),
          isFalse);
    });

    test('ignores event on match', () {
      final conditionalTransition = NonEventTransition<int>(
          targets: ['cond'], condition: (int c) => c == 0);
      expect(conditionalTransition.matches(anEvent: 'anything', context: 0),
          isTrue);
    });
  });
}
