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

  group('implementations', () {
    group('utilities', () {
      // final txa = NonEventTransition(targets: ['a']);
      final txb = NonEventTransition<int>(targets: ['b']);
      final txc = NonEventTransition<int>(targets: ['c']);
      final txd = NonEventTransition<int>(targets: ['d']);
      final p1 = State<int>('p1', isFinal: true);
      final p2 = State<int>('p2', isFinal: true);
      final b = State<int>('b',
          transitions: [txc], substates: [p1, p2], isParallel: true);
      final d = State<int>('d', transitions: [txb]);
      final c = State<int>('c', substates: [d], transitions: [txd]);
      final a = State<int>('a', substates: [b, c], transitions: [txb]);

      final root = RootState<int>('root', [a]);
      final ctx =
          ExecutionContext<int>.forTest(root, activeIDs: ['b', 'p1', 'p2']);
      final rtRoot = ctx['root']!;
      final rtA = ctx['a']!;
      final rtB = ctx['b']!;
      final rtC = ctx['c']!;
      final rtP2 = ctx['p2']!;

      test(
          'ancestors(c)',
          () => expect(ctx.getProperAncestors(rtC).ids,
              containsAllInOrder(['a', 'root'])));

      test(
          'ancestors(b)',
          () => expect(ctx.getProperAncestors(rtB).ids,
              containsAllInOrder(['a', 'root'])));

      test('LCCA(root)',
          () => expect(ctx.findLCCA([rtRoot, rtA]).id, equals('root')));
      test('LCCA(a, b)',
          () => expect(ctx.findLCCA([rtB, rtA]).id, equals('root')));
      test(
          'LCCA(b, c)', () => expect(ctx.findLCCA([rtB, rtC]).id, equals('a')));

      test('isDescendent(b, root)',
          () => expect(ctx.isDescendant(rtB, rtRoot), isTrue));

      test('isDescendent(root, b)',
          () => expect(ctx.isDescendant(rtRoot, rtB), isFalse));

      test('isInFinalState(non-final probe)',
          () => expect(ctx.isInFinalState(rtA), isFalse));

      // N.B.We're testing one child pf a parallel state.
      test('isInFinalState(final, atomic)',
          () => expect(ctx.isInFinalState(rtP2), isTrue));

      test('isInFinalState(parallel, all children final)',
          () => expect(ctx.isInFinalState(rtP2), isTrue));
    });
  });
}

extension TestHelpers<T> on Iterable<RuntimeState<T>> {
  Iterable<String> get ids => [for (var s in this) s.id!];
}
