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

class TransitionResolver<T> {
  /// The root of the tree (statechart).
  final RootState<T> root;
  final History<T> history;
  late final StateSet<T> selections, entrySet, exitSet, defaultEntrySet;

  TransitionResolver(ExecutionStep<T> step)
      : root = step.tree.root,
        history = step.history {
    final tree = step.tree;
    selections = StateSet(tree)..addAll(tree.activeStates);
    entrySet = StateSet(tree);
    exitSet = StateSet(tree);
    defaultEntrySet = StateSet(tree);
  }

  /// All targets of 'transition' after replacing any history states.
  @visibleForOverriding
  Set<State<T>> getEffectiveTargetStates(transition) {
    var targets = <State<T>>{};
    for (var s in transition.targetStates) {
      if (s is HistoryState<T>) {
        if (history.contains(s)) {
          targets.addAll(Set.of(history[s]!));
        } else {
          targets.addAll(getEffectiveTargetStates(s.transition));
        }
      } else {
        targets.add(s);
      }
    }
    return targets;
  }

  /// The smallest possible subtree containing all the transition targets.
  @visibleForOverriding
  State<T>? getTransitionDomain(Transition<T> t) {
    final tstates = getEffectiveTargetStates(t);
    if (tstates.isEmpty) {
      return null;
    }
    if (t.type == TransitionType.Internal &&
        t.source!.isCompound &&
        tstates.every((s) => s.descendsFrom(t.source!))) {
      return t.source;
    }
    return State.commonSubtree([t.source!, ...tstates]);
  }

  void selectAncestors(State<T> state, StateTreeBuilder<T> b,
      [History? history]) {
    var probe = state;
    var parent = state.parent;
    while (parent != null) {
      b.linkParent(probe, parent);
      probe = parent;
      parent = probe.parent;
    }
  }

  void selectDescendents(State<T> state, StateTreeBuilder<T> b,
      [History? history]) {
    if (state.isAtomic) return;
    var probe = state;
    while (probe.isCompound) {
      if (probe.isParallel) {
        for (var s in probe.substates) {
          b.select(s, type: NodeType.defaultEntry);
          selectDescendents(s, b, history);
        }
        break;
      } else {
        final next =
            probe.initialTransition?.targetStates ?? [probe.substates.first];
        if (next.isEmpty) break;
        if (next.length > 1) {
          for (var s in next) {
            if (b.isSelected(s)) continue;
            b.select(s);
            selectAncestors(s, b, history);
            selectDescendents(s, b, history);
          }
          break;
        } else {
          final child = next.single;
          if (b.isSelected(child)) break;
          b.select(child, type: NodeType.defaultEntry);
          probe = child;
        }
      }
    }
  }
}
