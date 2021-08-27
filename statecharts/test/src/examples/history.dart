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

import 'package:statecharts/statecharts.dart';

// Using the example from https://statecharts.dev/glossary/history-state.html

final EXIT = 'exit';
final RESTORE = 'restore';

final res = StateResolver<void>();
final history_statechart = RootState.newRoot<void>(
  'root',
  resolver: res,
  substates: [
    State(
      'A',
      substates: [
        // remember the exit state of A. If it hasn't been exited yet, use C as the default.
        HistoryState('A_AGAIN', transition: res.transition(targets: ['C'])),
        State('B'),
        State('C'),
        State('D'),
      ],
      initialTransition: res.transition(targets: ['B']),
      transitions: [
        res.transition(event: EXIT, targets: ['ALT']),
        res.transition(event: RESTORE, targets: ['A_AGAIN']),
      ],
    ),
    State(
      'ALT',
      transitions: [
        res.transition(event: RESTORE, targets: ['A_AGAIN']),
      ],
    ),
  ],
);
