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

// ignore_for_file: non_constant_identifier_names

import 'package:statecharts/statecharts.dart';

// Using the example from https://statecharts.dev/glossary/history-state.html

final DEEP = 'deep';
final EXIT = 'exit';
final RESTORE_A = 'restore';
final RESTORE_ALT = 'restore_alt';

final history_statechart = RootState<void>(
  'root',
  initialTransition: Transition(targets: ['A']),
  substates: [
    State(
      'A',
      substates: [
        // remember the exit state of A. If it hasn't been exited yet, use C as the default.
        HistoryState('A_AGAIN',
            transition: Transition(targets: ['C']), type: HistoryDepth.deep),
        State('B'),
        State('C'),
        State('D', substates: [State('D1'), State('D2')]),
      ],
      initialTransition: Transition(targets: ['B']),
      transitions: [
        Transition(event: EXIT, targets: ['ALT']),
        Transition(event: RESTORE_A, targets: ['A_AGAIN']),
        Transition(event: RESTORE_ALT, targets: ['ALT_AGAIN']),
        Transition(event: DEEP, targets: ['D2']),
      ],
    ),
    State(
      'ALT',
      substates: [
        State('ALT1'),
        State(
          'ALT2',
          substates: [State('ALT2a'), State('ALT2b')],
        ),
        HistoryState('ALT_AGAIN',
            transition: Transition(targets: ['C']), type: HistoryDepth.shallow),
      ],
      transitions: [
        Transition(event: RESTORE_A, targets: ['A_AGAIN']),
        Transition(event: RESTORE_ALT, targets: ['ALT_AGAIN']),
        Transition(event: DEEP, targets: ['ALT2b']),
      ],
    ),
  ],
);
