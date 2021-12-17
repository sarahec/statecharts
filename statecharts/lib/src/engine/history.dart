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

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:statecharts/statecharts.dart';

abstract class HistoryBase<T> {
  final RootState<T> root;

  @visibleForTesting
  final Map<State<T>, Iterable<State<T>>> entries;

  HistoryBase(this.root, [entries])
      : entries = entries ?? <State<T>, Set<State<T>>>{};

  Iterable<State<T>>? operator [](State<T> probe) => entries[probe];

  bool contains(State<T> state) => entries.containsKey(state);

  Iterable<State<T>> get keys => entries.keys;
}

class History<T> extends HistoryBase<T> {
  History(RootState<T> root, [entries]) : super(root, entries);

  HistoryBuilder<T> toBuilder() => HistoryBuilder(root, entries);
}

class HistoryBuilder<T> extends HistoryBase<T> {
  HistoryBuilder(RootState<T> root,
      [Map<State, Iterable<State>> entries = const {}])
      : super(root, Map<State<T>, Iterable<State<T>>>.of(entries.cast()));

  History<T> build() => History(root, UnmodifiableMapView(entries));

  void add(State<T> s, Iterable<State<T>> values) {
    if (values.isNotEmpty) entries[s] = values;
  }
}

/*
  @visibleForOverriding
  Iterable<State<T>> replaceHistoryStates(
      Iterable<State<T>> selections, History<T> fromHistory) {
    final _historyStates = selections.whereType<HistoryState<T>>();
    if (_historyStates.isEmpty) return selections;
    final concreteStates = selections.toSet();
    concreteStates.removeAll(_historyStates);
    for (var h in _historyStates) {
      concreteStates.addAll(fromHistory[h] ?? h.transition.targetStates);
    }
    return concreteStates;
  }
*/

