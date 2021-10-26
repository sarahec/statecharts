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
  group('with lightswitch', () {
    MutableStateTree<Lightbulb>? tree;
    RootState<Lightbulb>? root;

    setUp(() async {
      root = lightswitch;
      tree = MutableStateTree(root!);
    });

    // There's no initial transition, so all active nodes should be flagged
    // as "initial"
    test('selects initial states', () {
      expect(tree!.entryStates.ids, equals(['lightswitch', 'off']));
      expect(tree!.exitStates, isEmpty);
    });
  });
}
