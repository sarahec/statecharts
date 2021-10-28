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

class MutableStateTree<T> implements StateTree<T> {
  @override
  final RootState<T> root;
  final List<StateInfo<T>> _substates;

  factory MutableStateTree(RootState<T> root) {
    final allNodes = List.of(root.toIterable, growable: false);
    final substates = List.of([for (var s in allNodes) StateInfo(s)]);
    return MutableStateTree._(root, substates)..addDescendents(root);
  }

  MutableStateTree._(this.root, this._substates);

  @override
  Iterable<State<T>> get activeStates =>
      _substates.where((s) => isSelected(s.state)).map((s) => s.state);

  @override
  Iterable<State<T>> get defaultEntryStates => _substates
      .where((s) => s.type == NodeType.defaultEntry)
      .map((s) => s.state);

  @override
  Iterable<State<T>> get entryStates => _substates
      .where((s) => s.type == NodeType.defaultEntry || s.type == NodeType.entry)
      .map((s) => s.state);

  @override
  Iterable<State<T>> get exitStates =>
      _substates.where((s) => s.type == NodeType.exit).map((s) => s.state);

  @override
  bool get isEmpty => _substates.every((info) => info.type == NodeType.none);

  /// Adds [node] and all of its ancestors up to [root].
  void addAncestors(State<T> node, [NodeType type = NodeType.entry]) {
    var probe = node;
    while (probe.parent != null) {
      final parent = probe.parent!;
      if (_substates[parent.order].type != NodeType.none) {
        break;
      } // already populated
      if (parent.isParallel) {
        addParallelState(parent, NodeType.entry);
      } else {
        _substates[parent.order]
          ..type = type
          ..children = [probe];
      }
      probe = parent;
    }
  }

  /// Walks down from [node], selecting the default descendents.
  ///
  /// This stops when it reaches an already processed node.
  /// Note that the nodes are added to [_substates] from the
  /// bottom up as [_substates] shows the parent-child relationship.
  void addDescendents(State<T> node, [NodeType type = NodeType.defaultEntry]) {
    var probe = node;
    while (probe.isCompound && _substates[probe.order].children.isEmpty) {
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
    addState(probe, type);
    addAncestors(probe, type);
  }

  /// Adds a parallel state and all its descendents.
  void addParallelState(State<T> state, [NodeType type = NodeType.entry]) {
    assert(state.isParallel);
    _substates[state.order]
      ..type = type
      ..children = List.of(state.substates);
    for (var s in state.substates) {
      addDescendents(s, NodeType.entry);
    }
  }

  /// Adds all of the nodes from [selected], plus ancestors and descendents.
  void addSelections(Iterable<State<T>> selections) {
    for (var s in selections) {
      addDescendents(s);
    }
    for (var s in selections) {
      addAncestors(s);
    }
  }

  void addState(State<T> node, [NodeType type = NodeType.entry]) {
    final info = _substates[node.order];
    if (info.type == NodeType.none || info.type == NodeType.exit) {
      info.type = type;
    }
  }

  /// Returns an immutable copy of this tree.
  StateTree<T> build() => this;

  /// Finds the state with the matching ID.
  @override
  State<T>? find(String id) =>
      _substates.firstWhereOrNull((info) => info.state.id == id)?.state;

  bool isSelected(State<T> s) => !(const [NodeType.none, NodeType.exit]
      .contains(_substates[s.order].type));

  /// Removes the specified nodes (and their descendents) from the tree.
  void removeAll(Iterable<State<T>> nodes) {
    for (var s in nodes) {
      switch (_substates[s.order].type) {
        case NodeType.none:
        case NodeType.exit:
          // nop.
          break;
        case NodeType.selected:
        case NodeType.entry:
        case NodeType.defaultEntry:
          _substates[s.order].type = NodeType.exit;
          break;
      }
      removeAll(_substates[s.order].children);
      _substates[s.order].children = [];
    }
  }

  /// Removes [node] and all its descendents form the tree.
  void removeSubtree(State<T> node) => removeAll(subtreeOf(node));

  /// Return the descendents of [node].
  ///
  /// Note that this looks at the node type and skips deleted nodes.
  @override
  Iterable<State<T>> subtreeOf(State<T> node) sync* {
    var probe = node;
    yield probe;

    while (probe.isCompound) {
      final next = _substates[probe.order].children;
      assert(next.isNotEmpty,
          'Error: compound State $probe is missing its substates');
      if (next.length == 1) {
        probe = next.single;
        if (isSelected(probe)) {
          yield probe;
        }
      } else {
        assert(probe.isParallel,
            'Error: Found multiple children of non-parallel State $probe');
        for (var s in next) {
          yield* subtreeOf(s);
        }
        break;
      }
    }
  }

  // Locates the node with the given ID
  /// Copies an immutable [StateTree] into a fresh mutable one.
  ///
  /// This also converts `entry` nodes into `selected` and prunes `exit` nodes.
  @override
  MutableStateTree<T> toBuilder() => MutableStateTree._(
      root, [for (var si in _substates) si.makeNext()].toList(growable: false));
}

enum NodeType { none, selected, entry, defaultEntry, exit }

class StateInfo<T> {
  final State<T> state;
  NodeType type;
  List<State<T>> children;

  StateInfo(this.state, [this.type = NodeType.none, this.children = const []]);

  /// Duplicates this info, making it ready for the next tree generation.
  ///
  /// In particular, [NodeType.exit] nodes become [NodeType.none] and all other
  /// selected or entry nodes become [NodeType.selected].
  StateInfo<T> makeNext() {
    if (type == NodeType.none || type == NodeType.exit) {
      return StateInfo(state); // no children
    } else {
      return StateInfo(state, NodeType.selected, List.of(children));
    }
  }

  void reset() {
    type = NodeType.none;
    children = [];
  }
}

abstract class StateTree<T> {
  factory StateTree(RootState<T> root) => MutableStateTree(root);

  Iterable<State<T>> get activeStates;

  Iterable<State<T>> get defaultEntryStates;

  Iterable<State<T>> get entryStates;

  Iterable<State<T>> get exitStates;

  bool get isEmpty;

  RootState<T> get root;

  State<T>? find(String id);

  Iterable<State<T>> subtreeOf(State<T> node);

  MutableStateTree<T> toBuilder() => this as MutableStateTree<T>;
}
