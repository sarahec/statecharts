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
import 'package:statecharts/statecharts.dart';

enum NodeType { none, entry, defaultEntry, exit };

class MutableStateTree<T> implements StateTree<T> {
  @override
  final RootState<T> root;
  final int _length;
  final List<Iterable<State<T>>?> _substates;
  final List<NodeType> _nodeTypes;
  
  @override
  Iterable<State<T>> get entryStates => UnmodifiableListView(_entryStates);

  @override
  Iterable<State<T>> get exitStates => UnmodifiableListView(_exitStates);

  factory MutableStateTree(RootState<T> root) {
    final length = root.toIterable.length;
    final substates =
        List<Iterable<State<T>>?>.filled(length, null, growable: false);
    final nodeTypes = List<NodeType>.filled(length, NodeType.none, growable: false);
    return MutableStateTree._(root, length, substates, nodeTypes);
  }

  MutableStateTree._(this.root, this._length, this._substates, this._nodeTypes);

  @override
  bool get isEmpty => _substates.every((element) => element == null);

  @override
  Iterable<State<T>> get toIterable => subtreeOf(root);

  void addAncestors(State<T> node) {
    var probe = node;
    while (probe.parent != null) {
      final parent = probe.parent!;
      final index = parent.order;
      if (_substates[index] != null) break; // already populated
      if (parent.isParallel) {
        _substates[index] = parent.substates;
      } else {
        _substates[index] = [probe];
      }
      probe = parent;
    }
  }

  void addDescendents(State<T> node) {
    var probe = node;
    while (probe.isCompound && _substates[probe.order] == null) {
      if (probe.isParallel) {
        for (var s in probe.substates) {
          addDescendents(s);
        }
      } else {
        // not parallel
        final targetStates = probe.initialTransition?.targetStates;
        if (targetStates != null) {
          for (var s in targetStates) {
            addDescendents(s);
          }
        } else {
          probe = probe.substates.first;
        }
      }
    }
    addAncestors(probe);
  }

  void addSelections(Iterable<State<T>> selections) {
    for (var s in selections) {
      addDescendents(s);
    }
    for (var s in selections) {
      addAncestors(s);
    }
  }

  MutableStateTree<T> clone() => MutableStateTree._(root, _length, List.of(_substates, growable: false), List<NodeType>.filled(_length, NodeType.none, growable: false));

  void removeAll(Iterable<State<T>> nodes) {
    for (var s in nodes) {
      _substates[s.parent?.order ?? 0] = null;
    }
  }

  void removeSubtree(State<T> node) => removeAll(subtreeOf(node));

  Iterable<State<T>> subtreeOf(State<T> node) sync* {
    var probe = node;
    yield probe;

    while (probe.isCompound) {
      final next = _substates[probe.order];
      assert(next != null,
          'Error: compound state $probe is missing its substates');
      if (next!.length == 1) {
        probe = next.first;
        yield probe;
      } else {
        for (var s in next) {
          yield* subtreeOf(s);
        }
      }
    }
  }
}

abstract class StateTree<T> {
  Iterable<State<T>> get entryStates;

  Iterable<State<T>> get exitStates;

  bool get isEmpty;

  RootState<T> get root;

  Iterable<State<T>> get toIterable;
}
