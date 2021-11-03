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

enum NodeType { none, selected, entry, ancestorEntry, defaultEntry, exit }

typedef HistoryResolver = Iterable<State<T>> Function<T>(HistoryState<T> state);

class StateInfo<T> {
  final State<T> state;
  final NodeType type;
  final Iterable<State<T>> children;

  StateInfo(this.state, [this.type = NodeType.none, this.children = const []]);

  bool get isEntry =>
      type == NodeType.ancestorEntry ||
      type == NodeType.entry ||
      type == NodeType.defaultEntry;
  bool get isExit => type == NodeType.exit;
  bool get isFree => type == NodeType.none || type == NodeType.exit;
  bool get isSelected => type != NodeType.none && type != NodeType.exit;

  /// Duplicates this info, making it ready for the next tree generation.
  ///
  /// In particular, [NodeType.exit] nodes become [NodeType.none] and all other
  /// selected or entry nodes become [NodeType.selected].
  StateInfo<T> makeNext() => isFree
      ? StateInfo(state)
      : StateInfo(state, NodeType.selected, List.of(children));
}

class StateTree<T> extends StateTreeBase<T> {
  StateTree(RootState<T> root)
      : super(root, List.of([for (var s in root.toIterable) StateInfo(s)]));

  StateTree._(root, substates) : super(root, substates);

  Iterable<State<T>> get activeStates =>
      substates.where((s) => isSelected(s.state)).map((s) => s.state);

  Iterable<State<T>> get defaultEntryStates => substates
      .where((s) => s.type == NodeType.defaultEntry)
      .map((s) => s.state);

  Iterable<State<T>> get entryStates => substates
      .where((s) => s.type == NodeType.defaultEntry || s.type == NodeType.entry)
      .map((s) => s.state);

  Iterable<State<T>> get exitStates =>
      substates.where((s) => s.type == NodeType.exit).map((s) => s.state);

  bool get isEmpty => substates.every((info) => info.type == NodeType.none);

  StateTreeBuilder<T> toBuilder() => StateTreeBuilder.from(this);
}

class StateTreeBase<T> {
  final RootState<T> root;
  final List<StateInfo<T>> substates;

  StateTreeBase(this.root, this.substates);

  State<T>? find(String id) =>
      substates.firstWhereOrNull((info) => info.state.id == id)?.state;

  StateInfo<T> info(State<T> state) => substates[state.order];

  bool isSelected(State<T> s) => substates[s.order].isSelected;

  Iterable<State<T>> ancestors(State<T> node, {State<T>? upTo}) sync* {
    var probe = node;
    while (probe.parent != upTo) {
      final parent = probe.parent!;
      yield parent;
      probe = parent;
    }
  }

  /// Return the active descendents of [node].
  ///
  /// Note that this looks at the node type and skips deleted nodes.
  Iterable<State<T>> descendents(State<T> node) sync* {
    var probe = node;
    while (probe.isCompound) {
      final children = substates[probe.order].children;
      if (probe.isParallel) {
        for (var s in children) {
          yield* descendents(s);
        }
      } else {
        probe = children.single;
        if (isSelected(probe)) {
          yield probe;
        }
      }
    }
  }
}

class StateTreeBuilder<T> extends StateTreeBase<T> {
  factory StateTreeBuilder.from(StateTree<T> tree) {
    final substates = List.of(tree.substates);
    return StateTreeBuilder._(tree.root, substates);
  }

  StateTreeBuilder._(root, substates) : super(root, substates);

  /// Returns an immutable copy of this tree.
  StateTree<T> build() => StateTree._(root, UnmodifiableListView(substates));

  /// Removes the specified node (and its descendents) from the tree.
  void deselect(State<T> state, {bool andDescendents = false}) {
    if (info(state).isFree) return;
    final queue = [state];
    if (andDescendents) queue.addAll(descendents(state));
    for (var s in queue) {
      free(s);
    }
  }

  /// Removes a single state without touching its descendents.
  @visibleForOverriding
  void free(State<T> state) {
    if (info(state).isFree) return;
    unlinkParent(state);
    updateInfo(state, type: NodeType.exit, children: const []);
  }

  void select(State<T> state, {type = NodeType.selected}) {
    if (info(state).isSelected) return;
    updateInfo(state, type: type);
    if (state.parent != null) linkParent(state, state.parent!);
  }

  void selectAll(Iterable<State<T>> states) {
    for (var s in states) {
      select(s);
    }
  }

  void linkParent(State<T> state, State<T> parent) {
    final children = parent.isParallel ? parent.substates : [state];
    updateInfo(parent, type: NodeType.ancestorEntry, children: children);
  }

  void unlinkParent(State<T> state) {
    if (state.parent == null) return;
    final children = info(state.parent!).children.toList()..remove(state);
    updateInfo(state.parent!, children: children);
  }

  @visibleForOverriding
  void updateInfo(State<T> probe,
      {NodeType? type, Iterable<State<T>>? children}) {
    final info = substates[probe.order];
    substates[probe.order] =
        StateInfo(probe, type ?? info.type, children ?? info.children);
  }
}
