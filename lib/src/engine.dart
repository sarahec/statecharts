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
import 'package:meta/meta.dart';

class Engine<T> {
  final State<T> statechart;
  final T? context;

  var _activeStates;

  final Map<String, State<T>> _nodesByID;

  Engine(this.statechart, [this.context])
      : _nodesByID = {for (var s in statechart.flatten) s.id: s},
        _activeStates = statechart.initialStates;

  Iterable<State<T>> get activeStates => _activeStates;

  @protected
  set activeStates(Iterable<State> value) => _activeStates = value;

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
