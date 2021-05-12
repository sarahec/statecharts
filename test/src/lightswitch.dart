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

class Lightbulb {
  int cycleCount = 0;
  bool isOn = false;
}

const turnOn = 'turnOn';
const turnOff = 'turnOff';

final stateOff = State<Lightbulb>('off',
    isInitial: true,
    transitions: [
      Transition<Lightbulb>(targets: ['on'], event: turnOn)
    ],
    onEntry: (b) => b.isOn = false);
final stateOn = State<Lightbulb>('on',
    transitions: [
      Transition<Lightbulb>(targets: ['off'], event: turnOff)
    ],
    onEntry: (b) => b.isOn = true,
    onExit: (b) {
      b.cycleCount += 1;
    });

final lightswitch = RootState<Lightbulb>(
  'lightswitch',
  [
    stateOff,
    stateOn,
  ],
);

final countedLightswitch = State<Lightbulb>('lightswitch2', substates: [
  State<Lightbulb>('off',
      isInitial: true,
      transitions: [
        EventTransition<Lightbulb>(
            targets: ['on'],
            event: turnOn,
            condition: (b) => b.cycleCount < 10),
      ],
      onEntry: (b) => b.isOn = false),
  State<Lightbulb>('on',
      transitions: [
        EventTransition<Lightbulb>(targets: ['off'], event: turnOff),
      ],
      onEntry: (b) => b.isOn = true,
      onExit: (b) {
        b.cycleCount += 1;
      }),
]);
