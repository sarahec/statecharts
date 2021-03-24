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
import 'package:meta/meta.dart';
import 'package:quiver/collection.dart';
import 'package:quiver/core.dart';
import 'package:statecharts/statecharts.dart';

// final _log = Logger('Statechart');

class Statechart<T> extends StateNode<T> {
  final Iterable<State<T>> states;

  const Statechart(id, this.states, {onEntry, onExit})
      : assert(states.length > 0, 'at least one state required'),
        super(id, onEntry: onEntry, onExit: onExit);

  @override
  Set<String> get events {
    final result = <String>{};

    for (var s in states) {
      result.addAll(s.events);
    }
    return result;
  }

  @override
  int get hashCode => hash4(states, id, onEntry, onExit);

  State<T> get initialState =>
      states.length == 1 ? states.first : states.firstWhere((s) => s.isInitial);

  @visibleForTesting
  Set<String> get paths => {for (var event in events) '$id.$event'};

  @override
  bool operator ==(Object other) =>
      other is Statechart &&
      id == other.id &&
      onEntry == other.onEntry &&
      onExit == other.onExit &&
      listsEqual(List.of(states), List.of(other.states));

  State<T> findState({required String id, bool inChildren = false}) =>
      states.firstWhere(
          (s) => s.id == id); // cast away return_of_invalid_type_from_closure

  bool hasStateNamed(String id) => states.any((s) => s.id == id);

  State<T>? stateNamed(String id) =>
      states.firstWhere((s) => s.id == id, orElse: () => null as dynamic);
}
