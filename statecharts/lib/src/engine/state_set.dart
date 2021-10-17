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

import 'package:statecharts/statecharts.dart';

/// Fast ordered set implementation using [State.order].
///
/// Since we know that the states in a tree each have a unique `order`
/// value starting at 0, we can get the size of the tree and allocate
/// a fixed-length list of that size. Most operations then become a
/// quick list lookup
class StateSet<T> extends SetBase<State<T>> {
  final int _size;
  final List<State<T>?> _storage;

  StateSet({required int size})
      : _size = size,
        _storage = List.filled(size, null);

  @override
  bool add(State<T> state) {
    if (state.order >= _size) {
      throw ArgumentError.value(
          state.order, 'state', 'Size $_size is too small to hold this value');
    }
    final found = _storage[state.order] != null;
    if (!found) _storage[state.order] = state;
    return found;
  }

  @override
  bool contains(Object? probe) =>
      probe != null &&
      probe is State<T> &&
      probe.order < _size &&
      _storage[probe.order] == probe;

  @override
  Iterator<State<T>> get iterator => toList().iterator;

  @override
  int get length => _size;

  @override
  State<T>? lookup(Object? probe) => contains(probe) ? probe as State<T> : null;

  @override
  bool remove(Object? value) {
    if (contains(value)) {
      _storage[(value as State<T>).order] = null;
      return true;
    }
    return false;
  }

  @override
  Set<State<T>> toSet() =>
      Set.of(_storage.where((s) => s != null) as Iterable<State<T>>);

  @override
  List<State<T>> toList({bool growable = false}) =>
      List.of(_storage.where((s) => s != null) as Iterable<State<T>>,
          growable: growable);
}
