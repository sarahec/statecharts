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

import 'dart:async';

import 'package:logging/logging.dart';
import 'package:statecharts/statecharts.dart';

final _log = Logger('StateResolver');

/// Used during construction to refer to a state by ID and resolve it to a
/// concrete state later.
///
/// ```
/// const turnOn = 'turnOn';
/// const turnOff = 'turnOff';
/// final res = StateResolver<Lightbulb>();
/// final stateOff = State<Lightbulb>('off',
///    transitions: [
///     res.transition(targets: ['on'], event: turnOn)
///   ],
///   onEntry: (b, _) => b!.isOn = false);
/// final stateOn = State<Lightbulb>('on',
///    transitions: [
///      res.transition(targets: ['off'], event: turnOff)
///    ],
///    onEntry: (b, _) => b!.isOn = true,
///    onExit: (b, _) {
///      b!.cycleCount += 1;
///    });
///
/// final lightswitch = RootState.newRoot<Lightbulb>(
///    'lightswitch',
///    [
///      stateOff,
///      stateOn,
///    ],
///    resolver: res);
/// ```
///

class StateResolver<T> {
  final _completer = Completer<RootState<T>>();

  /// Get the root of the tree.
  Future<RootState<T>> get root async => _completer.future;

  /// Resolves all of the state futures in the tree.
  void complete(RootState<T> root) => _completer.complete(root);

  /// Creates a placeholder for the state with a given ID. Resolves after calling
  /// [complete].
  ///
  /// This is used when creating a new statechart. A transition may refer
  /// to a state that doesn't exist yet, so this creates a placeholder
  /// for that state. This will be resolved once the whole tree is done.
  Future<State<T>?> state(String id) async =>
      root.then((r) => r.find(id)).then((result) {
        if (result == null) {
          _log.warning("Could not find id '$id'");
        }
        return result;
      });

  /// Creates a transition placeholder referencing all its states by ID.
  ///
  /// Use this to create a new transition within a state that you're
  /// defining. The [RootState] constructor will resolve these.
  ///
  /// ```
  /// /// final stateOff = State<Lightbulb>('off',
  ///    transitions: [
  ///     res.transition(targets: ['on'], event: turnOn)
  ///   ],
  ///   onEntry: (b, _) => b!.isOn = false);
  /// ```
  ///
  Future<Transition<T>> transition(
      {targets = const <String>[],
      String? event,
      Condition<T>? condition,
      Duration? after,
      type = TransitionType.External}) async {
    return Future.wait([for (var id in targets) state(id)]).then((targets) =>
        Transition<T>(
            targets: targets.cast<State<T>>(),
            event: event,
            condition: condition,
            after: after,
            type: type));
  }
}
