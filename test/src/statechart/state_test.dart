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
  group('standalone state', () {
    final state = State('a');

    test('is atomic', () => expect(state.isAtomic, isTrue));

    test('generates iterable',
        () => expect(state.toIterable, containsAllInOrder([state])));
  });

  group('nested state', () {
    final a11 = State('a11');
    final a1 = State('a1', substates: [a11]);
    final a2 = State('a2');
    final a = State('a', substates: [a1, a2]);

    test('is not atomic', () => expect(a.isAtomic, isFalse));

    test('generates depth-first iterable',
        () => expect(a.toIterable, containsAllInOrder([a, a1, a11, a2])));
  });

  group('initial state', () {
    test('first substate is implicit initial state', () {
      final singularity = State('singularity', substates: [State('one')]);
      expect(singularity.initialSubstate.id, equals('one'));
    });
  });
}
