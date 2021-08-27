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

enum HistoryDepth { SHALLOW, DEEP }

/// Signals the engine to return to a previous configuration of active states.
///
/// When the engine enters this state, it looks up the states active when State
/// [id] exited and uses those instead.
class HistoryState<T> implements State<T> {
  @override
  final String? id;

  /// Whether to replace with state [id] ([HistoryDepth.SHALLOW]) or
  /// with the state and all its descendents ([HistoryDepth.DEEP]).
  final HistoryDepth type;

  /// Specifies the default active states if none found in the history.
  final Transition transition;

  HistoryState(this.id, this.transition, [this.type = HistoryDepth.DEEP]);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
      'Not in History pseudo-state: ${invocation.memberName}');
}
