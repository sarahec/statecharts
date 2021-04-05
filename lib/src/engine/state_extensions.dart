import 'package:statecharts/statecharts.dart';

/**
 * Copyright 2021 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

extension TreeWalker<T> on State<T> {
  void walkTree(bool Function(State<T>) callback) => _walk(callback, this);

  void _walk(bool Function(State<T>) callback, State<T> container) {
    if (!callback(container)) return;
    for (var probe in container.substates) {
      if (probe.substates.isNotEmpty) {
        _walk(callback, probe);
      } else {
        callback(probe);
      }
    }
  }
}

extension Flatten<T> on State<T> {
  Iterable<State<T>> get flatten {
    final result = <State<T>>[];
    walkTree((s) {
      result.add(s);
      return true;
    });
    return result;
  }
}

extension InitialStates<T> on State<T> {
  Iterable<State<T>> get initialStates {
    final result = <State<T>>[];
    walkTree((s) {
      result.add(s);
      return true;
    });
    return result;
  }
}
