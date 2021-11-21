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

enum HistoryDepth { shallow, deep }

/// Signals the engine to return to a previous configuration of active states.
///
/// When the engine enters this state, it looks up the states active when State
/// [id] exited and uses those instead.
class HistoryState<T> implements State<T> {
  @override
  final String? id;

  /// Whether to replace with state [id] ([HistoryDepth.shallow]) or
  /// with the state and all its descendents ([HistoryDepth.deep]).
  final HistoryDepth type;

  /// Specifies the default active states if none found in the history.
  final Transition<T> transition;

  /// Index into its parent's substates
  @override
  late final int order;

  /// This node's parent (assigned late)
  @override
  late final State<T>? parent;

  HistoryState(this.id,
      {required this.transition, this.type = HistoryDepth.deep});

  /// Not applicable
  @override
  Transition<T>? get initialTransition => null;

  @override
  bool get isAtomic => true;

  /// True if this has at least one substate.
  @override
  bool get isCompound => false;

  /// States contained within this one
  @override
  Iterable<State<T>> get substates => [];

  /// All transitions from this state.
  @override
  Iterable<Transition<T>> get transitions => [transition];

  /// No-op in a history state.
  @override
  void enter(T? context, [EngineCallback? callback]) {}

  /// No-op in a history state.
  @override
  void exit(T? context, [EngineCallback? callback]) {}

  /// Report on unimplemented methods.
  ///
  /// Most methods and fields don't apply to a `HistoryState`, so implement
  /// only the necessary ones and signal a problem anytime we use an
  /// unimplemented one.
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
      'Not implemented in History pseudo-state: ${invocation.memberName}');

  /// Populate [source] and [transition.targetStates]
  @override
  void resolveTransitions(Map<String, State<T>> stateMap) {
    transition.resolveStates(this, stateMap);
  }

  @override
  String toString() => '($id, $transition, $type)';
}
