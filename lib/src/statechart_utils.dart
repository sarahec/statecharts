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

import 'package:statecharts/src/state.dart';
import 'package:statecharts/src/state_node.dart';
import 'package:statecharts/src/statechart.dart';

extension ListChildren<T> on Statechart<T> {
  Iterable<StateNode<T>> get flatten sync* {
    yield* listChildren(this);
  }

  Iterable<StateNode<T>> listChildren(StateContainer<T> container) sync* {
    yield container as StateNode<T>;
    for (var s in container.children) {
      yield s;
      if (s is StateContainer<T>) {
        yield* listChildren(s);
      }
    }
  }

} 


extension ContainerMap<T> on Statechart<T> {
  Map<State<T>, StateContainer<T>> get containerMap =>
      Map.fromEntries(containerMapEntries(this));

  MapEntry<State<T>, StateContainer<T>> containerMapEntries(
      StateContainer<T> container) sync* {
    for (var s in container.children) {
      yield MapEntry(s, container);
      if (s is StateContainer<T>) {
        yield* containerMapEntries(s);
      }
  }
}
