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
import 'package:statecharts/statecharts.dart';

class Engine<T> {
  final RuntimeState<T> root;
  final T? context;
  var _executionContext;

  Iterable<RuntimeState<T>> _configuration = {};
  var _statesToInvoke;

  var _datamodel;
  var _internalQueue;
  var _externalQueue;
  var _historyValue;
  var _running;
  var _binding;
  var _historyValues;

  Engine(RootState<T> startNode, [this.context])
      : root = RuntimeState.wrapSubtree(startNode);

  Iterable<State<T>> get activeStates =>
      [for (var i in _configuration) i.state];

  ExecutionContext<T> get executionContext => _executionContext;

  bool execute({String? anEvent, Duration? elapsedTime}) {
    // assert(_activeStates.isNotEmpty);
    throw UnimplementedError();
    // // Get the available transitions
    // final startingState = _activeStates.first;
    // final transition =
    //     startingState.transitionFor(event: anEvent, context: context);
    // final endingState =
    //     statechart.find(id: transition.targetId, inChildren: false);
    // if (endingState.id != startingState.id) {
    //   startingState.exit(context);
    //   endingState.enter(context);
    //   _activeStates[_activeStates.indexOf(startingState)] = endingState;
    // }
    // return endingState.id != startingState.id;
  }
}
