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

/// Steps through the statechart, calling the [State.onEntry] and [State.onExit]
/// methods to alter the data in the [context].
///
/// Usage:
/// 1. Create a state machine (here called `Lightswitch`) and its data context
/// (`lightbulb`).
/// 2. Initialize the engine, then feed it events and timestamps.
///
/// ```
/// final lightswitch = RootState<Lightbulb>(
///    'lightswitch', [stateOff, stateOn]);
///
/// final engine = Engine.initial<Lightbulb>(ls, bulb));
/// // Execute an event
/// await engine.execute(anEvent: 'turnOn');
/// ```
class Engine<T> {
  /// The root of the tree (statechart).
  final RootState<T> root;

  ExecutionStep<T> _currentStep;

  /// Passed to [Transition.action], [State.onEntry], and [State.onExit].
  final EngineCallback? callback;

  /// Creates an engine.
  ///
  /// [root] The [RootState].
  /// [context] The data object.
  /// [step] The current step. If unspecified, creates a new, initial step.
  /// [callback] Signaling mechanism back to the engine.
  Engine(this.root, {T? context, ExecutionStep<T>? step, this.callback})
      : _currentStep = ExecutionStep(StateTree(root), context);

  /// The data this engine is managing.
  T? get context => _currentStep.context;

  /// Current execution state.
  ExecutionStep<T> get currentStep => _currentStep;

  /// Updates the nodes in the tree by applying [transitions] in document order.
  StateTree<T> applyTransitions(Iterable<Transition<T>> transitions,
      StateTree<T> tree, History<T> history) {
    final orderedTransitions = List.of(transitions, growable: false)
      ..sort((t1, t2) => (t2.source?.order ?? 0) - (t1.source?.order ?? 0));
    if (orderedTransitions.isEmpty) return tree;
    final b = tree.toBuilder();
    for (var t in orderedTransitions) {
      final domain = getTransitionDomain(t, history);
      assert(domain != null);
      b.deselect(domain!, andDescendents: true);
      final selections = [for (var targetID in t.targets) tree.find(targetID)!];
      b.selectAll(selections);
      for (var s in selections.reverseSorted) {
        selectAncestors(s, b);
        selectDescendents(s, b);
      }
    }
    return b.build();
  }

  T? buildContext(dynamic ctx) => ctx;

  dynamic contextToBuilder(T? context) => context;

  /// Executes the matching transitions, returning `true` if anything changes.
  ///
  /// May execute additional transitions where [Transition.condition] matches.
  ///
  /// [anEvent] The event name to match.
  /// [elapsedTime] The time to match.
  bool execute({String? anEvent, Duration? elapsedTime}) {
    final transitions = getTransitions(_currentStep, anEvent, elapsedTime);
    if (transitions.isEmpty) {
      return false;
    }

    final history = currentStep.history.toBuilder();

    final tree = applyTransitions(transitions, currentStep.tree, history);

    final ctx = contextToBuilder(currentStep.context);
    runTransitionActions(transitions, ctx, callback);
    runExitStates(tree, ctx, callback); // TODO pass history builder
    runDefaultEntries(tree, ctx, callback);
    runEntryStates(tree, ctx, callback);
    final context = buildContext(ctx);
    _currentStep = ExecutionStep(tree, context, transitions, history.build());
    return true;
  }

  /// All targets of 'transition' after replacing any history states.
  @visibleForOverriding
  Set<State<T>> getEffectiveTargetStates(transition, History<T> history) {
    var targets = <State<T>>{};
    for (var s in transition.targetStates) {
      if (s is HistoryState<T>) {
        if (history.contains(s)) {
          targets = targets.union(Set.of(history[s]!));
        } else {
          targets =
              targets.union(getEffectiveTargetStates(s.transition, history));
        }
      } else {
        targets.add(s);
      }
    }
    return targets;
  }

  /// The smallest possible subtree containing all the transition targets.
  @visibleForOverriding
  State<T>? getTransitionDomain(Transition<T> t, History<T> history) {
    final tstates = getEffectiveTargetStates(t, history);
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

  /// Locates the transactions used by [execute].
  @visibleForOverriding
  Iterable<Transition<T>> getTransitions(
          ExecutionStep<T> step, String? anEvent, Duration? elapsedTime) =>
      [
        for (var s in step.tree.activeStates)
          s.transitionFor(
              event: anEvent, elapsedTime: elapsedTime, context: step.context)
      ].where((t) => t != null).cast<Transition<T>>();

  void runDefaultEntries(StateTree<T> tree, ctx, EngineCallback? callback) {
    for (var s in tree.defaultEntryStates) {
      s.enter(context, callback);
    }
  }

  /// Calls [State.onEntry] on the step's entry states.
  @visibleForOverriding
  void runEntryStates(StateTree<T> tree, T? context,
      [EngineCallback? callback]) {
    for (var s in tree.entryStates) {
      s.enter(context, callback);
    }
  }

  /// Calls [State.onExit] on the step's exit states.
  @visibleForOverriding
  void runExitStates(StateTree<T> tree, T? context,
      [EngineCallback? callback]) {
    for (var s in tree.exitStates) {
      s.exit(context, callback);
    }
  }

  /// Runs [Transition.action] for the selected transitions.
  @visibleForOverriding
  void runTransitionActions(Iterable<Transition<T>> transitions, T? context,
      [EngineCallback? callback]) {
    for (var t in transitions) {
      if (t.action != null) t.action!(context, callback);
    }
  }

  void selectAncestors(State<T> state, StateTreeBuilder<T> b,
      [History? history]) {
    var probe = state;
    var parent = state.parent;
    while (parent != null && !b.isSelected(parent)) {
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
          b.select(probe, type: NodeType.defaultEntry);
          probe = child;
        }
      }
    }
  }
}
