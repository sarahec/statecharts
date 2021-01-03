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
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

final _log = Logger('statecharts/State');

typedef Action = void Function();

abstract class ChildState {}

class FinalState implements ChildState {
  final String id;
  final Action onEntry;
  final Action onExit;

  final dynamic doneData;

  FinalState({this.id, this.onEntry, this.onExit, this.doneData});
}

class InitialState {
  final Transition transition;

  InitialState({@required this.transition});
}

// class Invoke {
//   final Uri type;

//   final String typeExpr;
//   final Uri src;

//   final String srcExpr;
//   final String id;

//   final String idLocation;

//   final String nameList;
//   final bool autoForward;

//   final Param param;
//   final Finalize finalize;
//   final Content content;

//   Invoke(
//       {this.type,
//       this.typeExpr,
//       this.src,
//       this.srcExpr,
//       this.id,
//       this.idLocation,
//       this.nameList,
//       this.autoForward,
//       this.param,
//       this.finalize,
//       this.content});
// }

abstract class ParallelChild {}

class ParallelStates implements ChildState, ParallelChild {
  final String id;
  final Transition transition;
  final Action onEntry;
  final Action onExit;
  List<ParallelChild> body;

  final Action action;

  ParallelStates(
      this.id, this.transition, this.onEntry, this.onExit, this.action);
}

class State implements ChildState, ParallelChild {
  final String id;
  final String initial;
  final Iterable<Transition> transitions;
  final Action onEntry;
  final Action onExit;
  final Transition initialState;
  final List<ChildState> body;

  State(
      {this.id,
      this.initial,
      this.transitions,
      this.onEntry,
      this.onExit,
      this.initialState,
      this.body});

  bool get isAtomic => body?.isNotEmpty ?? true;
}

class Transition {
  final String event;
  final String cond;
  final String target;
  final String type;

  final Action action;

  Transition(
      {this.event,
      this.cond,
      this.target,
      this.type = 'external',
      this.action});
}
