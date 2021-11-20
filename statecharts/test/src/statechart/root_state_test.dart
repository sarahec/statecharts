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
  final a2 = State('a2');
  final a1 = State('a1');
  final a = State(
    'a',
    isParallel: true,
    substates: [a1, a2],
  );
  final tree = RootState('root', substates: [
    a,
  ]);

  group('construction', () {
    test(
        'parents',
        () => expect(
            tree.toIterable.map((s) => s.parent), equals([null, tree, a, a])));

    test(
        'order',
        () => expect(
            tree.toIterable.map((s) => s.order),
            equals([
              0,
              1,
              2,
              3,
            ])));
  });

  group('utilities', () {
    test('size', () => expect(tree.size, equals(4)));

    test('find', () => expect(tree.find('a1')?.id, equals('a1')));

    test('to iterable',
        () => expect(tree.toIterable, equals([tree, a, a1, a2])));

    test('ancestors', () {
      expect(a1.ancestors(), equals([a, tree]));
      expect(a1.ancestors(upTo: tree), equals([a]));
      expect(tree.ancestors(), equals([tree]));
    });

    test('descendsFrom', () {
      expect(tree.descendsFrom(tree), isTrue);
      expect(a1.descendsFrom(tree), isTrue);
      expect(a1.descendsFrom(a), isTrue);
      expect(a.descendsFrom(a1), isFalse);
      expect(a.descendsFrom(a), isFalse);
    });

    test('commonSubtree', () {
      expect(State.commonSubtree([a1, a2]), equals(a));
      expect(State.commonSubtree([a1, a]), equals(a));
      expect(State.commonSubtree([a1, a1]), equals(a1));
      expect(State.commonSubtree([a1, tree]), equals(tree));
    });
  });
}
