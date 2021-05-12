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
  group('initialization', () {
    final a = State<void>('a');
    final b = State<void>('b');

    test('selects first child by default', () {
      final root = RootState<void>('root', [a]);
      final executionContext = ExecutionContext.initial(root);
      expect(executionContext, isNotNull);
      expect(executionContext.statesToEnter.ids, contains('a'));
    });

    test('selects from initialRefs', () {
      final root = RootState<void>('root', [a, b], initialRefs: 'b');
      final executionContext = ExecutionContext.initial(root);
      expect(executionContext, isNotNull);
      expect(executionContext.statesToEnter.ids, contains('b'));
    });

    test('selects ancestors of initial', () {
      final root = RootState<void>('root', [a, b], initialRefs: 'b');
      final executionContext = ExecutionContext.initial(root);
      expect(executionContext, isNotNull);
      expect(executionContext.statesToEnter.ids, containsAll(['root', 'b']));
    }, skip: true);
  });

  group('utilities', () {
    // final txa = NonEventTransition(targets: ['a']);
    final txb = Transition<int>(targets: ['b']);
    final root = RootState<int>('root', [
      State<int>(
        'a',
        transitions: [txb],
        substates: [
          State<int>('b', transitions: [
            Transition<int>(targets: ['c'])
          ]),
          State<int>('c', substates: [
            State<int>('d', transitions: [
              txb,
            ]),
          ], transitions: [
            Transition<int>(targets: ['d'])
          ]),
        ],
      )
    ]);
    final ctx = ExecutionContext<int>.forTest(root);
    final rtRoot = ctx['root']!;
    final rtA = ctx['a']!;
    final rtB = ctx['b']!;
    final rtC = ctx['c']!;

    test('getTransition', () {
      final transition = ctx.getTransition('c');
      expect(transition!.source.id, equals('b'));
    });

    test("getTransition('c', 'b')", () {
      final transition = ctx.getTransition('c', inside: 'b');
      expect(transition!.source.id, equals('b'));
    });

    group('getProperAncestors', () {
      test(
          'root',
          () => expect(
              ctx.getProperAncestors(ctx['root']!).ids, equals(['root'])));

      test(
          'd',
          () => expect(ctx.getProperAncestors(ctx['d']!).ids,
              equals(['c', 'a', 'root'])));

      test(
          'd, a',
          () => expect(
              ctx.getProperAncestors(ctx['d']!, ctx['a']).ids, equals(['c'])));
    });

    group('LCCA', () {
      test(
          'root', () => expect(ctx.findLCCA([rtRoot, rtA]).id, equals('root')));
      test('a, b', () => expect(ctx.findLCCA([rtB, rtA]).id, equals('root')));
      test('b, c', () => expect(ctx.findLCCA([rtB, rtC]).id, equals('a')));
    });

    group('isDescendant', () {
      test('b, root', () => expect(ctx.isDescendant(rtB, rtRoot), isTrue));

      test('root, b', () => expect(ctx.isDescendant(rtRoot, rtB), isFalse));
    });

    // TODO Move this into a runtime test suite
    /* group('isInFinalState', () {
      test('isInFinalState(non-final probe)',
          () => expect(ctx.isInFinalState(rtA), isFalse));

      // N.B.We're testing one child pf a parallel state.
      test('isInFinalState(final, atomic)',
          () => expect(ctx.isInFinalState(rtP2), isTrue));

      test('isInFinalState(parallel, all children final)',
          () => expect(ctx.isInFinalState(rtP2), isTrue));
    });
    */
  });

  group('transitions', () {
    test('getEffectiveTargetStates (no history)', () {
      final ctx = ExecutionContext.forTest(lightswitch);
      final transitionOn = ctx.getTransition('on')!;
      final stateOn = ctx['on']!;
      final targetStates = ctx.getEffectiveTargetStates(transitionOn);
      expect(targetStates.length, equals(1));
      expect(targetStates.first, same(stateOn));
    });
  });
}

extension TestHelpers<T> on Iterable<RuntimeState<T>> {
  Iterable<String> get ids => [for (var s in this) s.id!];
}
