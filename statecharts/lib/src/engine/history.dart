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

import 'package:meta/meta.dart';
import 'package:statecharts/statecharts.dart';

class History<T> {
  final RootState<T> root;

  @visibleForOverriding
  final Map<State<T>, Iterable<State<T>>> entries;

  History(this.root) : entries = <State<T>, Set<State<T>>>{};

  History.from(History<T> prior)
      : root = prior.root,
        entries = Map.from(prior.entries);

  Iterable<State<T>>? operator [](State<T> probe) => entries[probe];

  void addValues(State<T> s, StateTree<T> tree) {}

  bool contains(State<T> state) => entries.containsKey(state);

  Iterable<State<T>> get keys => entries.keys;

  Iterable<State<T>> historyValuesFor(State<T> s, StateTree<T> tree) {
    assert(s.containsHistoryState);
    // Since this is called for states that are exiting, we have to use the prior active states
    final activeChildren = tree.descendents(s);
    final historyChildren = s.substates.whereType<HistoryState>();
    // From the spec:
    // If the 'type' of a <history> element is "shallow", the SCXML processor
    // must record the immediately active children of its parent before taking
    // any transition that exits the parent. If the 'type' of a <history>
    // element is "deep", the SCXML processor must record the active atomic
    // descendants of the parent before taking any transition that exits the
    // parent.
    //
    // Note that in a conformant SCXML document, a <state> or <parallel>
    // element may have both "deep" and "shallow" <history> children.
    final result = <State<T>>{};
    for (var hs in historyChildren) {
      if (hs.type == HistoryDepth.shallow) {
        result.addAll(activeChildren);
      } else {
        final deepChildren = [
          for (var c in activeChildren) tree.descendents(c).last
        ];
        result.addAll(deepChildren);
      }
    }
    return result;
  }

  History<T> toBuilder() => this;
  History<T> build() => this;
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

