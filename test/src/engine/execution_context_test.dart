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
    });
  });
}

extension TestHelpers<T> on Iterable<RuntimeState<T>> {
  Iterable<String> get ids => [for (var s in this) s.id!];
}
