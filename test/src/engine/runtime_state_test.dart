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
  final statechart = RootState(
    'root',
    [
      State('A', substates: [
        State('B'),
        State(
          'C',
          isParallel: true,
          substates: [State('C1'), State('C2')],
        ),
      ]),
    ],
  );

  final root = RuntimeState.wrapSubtree(statechart);

  test('find', () => expect(root.find('C')?.id, equals('C')));
  test('find (none)', () => expect(root.find('none'), isNull));

  test(
      'subtree',
      () => expect(
          root.toIterable.ids, equals(['root', 'A', 'B', 'C', 'C1', 'C2'])));
}
