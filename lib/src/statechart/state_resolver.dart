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

import 'package:statecharts/statecharts.dart';

// final _log = Logger('StateResolver');

class StateResolver<T> {
  final _rootCompleter = Completer<RootState<T>>();

  Future<Map<String, State<T>>> get lookupMap async =>
      root.then((root) => {for (var s in root.toIterable) s.id!: s});

  Future<RootState<T>> get root async => Future.value(_rootCompleter.future);

  void complete(RootState<T> root) => _rootCompleter.complete(root);

  Future<State<T>> find(String id) async => lookupMap.then((map) => map[id]!);

  Future<Transition<T>> transition(
      {targets = const <String>[],
      String? event,
      Condition<T>? condition,
      Duration? after,
      type = TransitionType.External}) async {
    final targetFutures = [for (var id in targets) find(id)];
    return Future.wait(targetFutures).then((targets) => Transition<T>(
        targets: targets,
        event: event,
        condition: condition,
        after: after,
        type: type));
  }
}
