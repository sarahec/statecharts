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

class StateResolver<T> {
  final _completer = Completer<RootState<T>>();

  Future<RootState<T>> get root async => _completer.future;

  void complete(RootState<T> root) => _completer.complete(root);

  Future<State<T>?> state(String id) async =>
      root.then((r) => r.find(id)).then((result) {
        if (result == null) {
          _log.warning("Could not find id '$id'");
        }
        return result;
      });

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
