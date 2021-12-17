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

import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:statecharts/statecharts.dart';

// ignore_for_file: avoid_renaming_method_parameters

/// Fast ordered set implementation using [State.order].
///
/// Since we know that the states in a tree each have a unique `order`
/// value starting at 0, we can get the size of the tree and allocate
/// a fixed-length list of that size. Most operations then become a
/// quick list lookup
class StateSet<T> extends SetBase<State<T>> {
  @visibleForTesting
  final int size;
  @visibleForTesting
  final List<State<T>?> storage;

  factory StateSet(RootState<T> root) =>
      StateSet._(root.size, List.filled(root.size, null));

  @Deprecated('Use StateSet(<RootState<T>> root) instead')
  factory StateSet.withSize(int size) =>
      StateSet._(size, List.filled(size, null));

  StateSet._(this.size, this.storage);

  @override
  Iterator<State<T>> get iterator => toList().iterator;

  @override
  int get length => storage.whereType<State<T>>().length;

  Set<State<T>> get unmodifiable => UnmodifiableSetView(this);

  @override
  bool add(State<T> state) {
    assert(state.order >= 0);
    if (state.order >= size) {
      throw ArgumentError.value(
          state.order, 'state', 'Size $size is too small to hold this value');
    }
    final isNew = storage[state.order] == null;
    if (isNew) storage[state.order] = state;
    return isNew;
  }

  /// All nodes in this set from `state` to the root, not including state.
  Iterable<State<T>> ancestors(State<T> state, {State<T>? upTo}) =>
      state.ancestors(upTo: upTo).where((s) => contains(s));

  @override
  bool contains(Object? probe) =>
      probe != null &&
      probe is State<T> &&
      probe.order < size &&
      storage[probe.order] == probe;

  /// All children of `state`, and their children, in this set. Excludes `state`.
  Iterable<State<T>> descendents(State<T> state) sync* {
    for (var s in storage.where((s) => s?.parent == state)) {
      yield s!;
      yield* descendents(s);
    }
  }

  @override
  State<T>? lookup(Object? probe) => contains(probe) ? probe as State<T> : null;

  @override
  bool remove(Object? value) {
    if (contains(value)) {
      storage[(value as State<T>).order] = null;
      return true;
    }
    return false;
  }

  @override
  List<State<T>> toList({bool growable = false}) {
    final result = storage.isEmpty
        ? List<State<T>>.empty()
        : UnmodifiableListView(
            List<State<T>>.of(storage.whereType<State<T>>(), growable: false));
    return result;
  }

  @override
  Set<State<T>> toSet() => StateSet._(size, List.of(storage, growable: false));
}
