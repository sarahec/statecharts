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

extension ID<T> on Iterable<State<T>> {
  /// The [id] values of all states sorted by [order]. Used for testing.
  @visibleForTesting
  Iterable<String> get ids => [for (var s in this) s.id ?? '_'];
}

extension Sort<T> on Iterable<State<T>> {
  Iterable<State<T>> get sorted =>
      (toList()..sort((a, b) => a.order.compareTo(b.order)));

  Iterable<State<T>> get reverseSorted =>
      (toList()..sort((a, b) => b.order.compareTo(a.order)));
}

extension SortTransitions<T> on Iterable<Transition<T>> {
  Iterable<Transition<T>> get sorted => (toList()
    ..sort((a, b) => (a.source?.order ?? -1).compareTo(b.source?.order ?? -1)));

  Iterable<Transition<T>> get reverseSorted => (toList()
    ..sort((a, b) => (b.source?.order ?? -1).compareTo(a.source?.order ?? -1)));
}
