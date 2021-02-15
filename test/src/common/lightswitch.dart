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

class Lightbulb {
  int cycleCount = 0;
  bool? isOn;
  bool? wasOn;
  bool masterSwitch = false;
}

const turnOn = 'turnOn';
const turnOff = 'turnOff';

final transitionOn = Transition<Lightbulb>('on',
    condition: (b) => b.cycleCount < 10, event: turnOn);
final transitionOff = const Transition<Lightbulb>('off', event: turnOff);
final stateOff = State<Lightbulb>('off',
    isInitial: true,
    transitions: [transitionOn],
    onEntry: (b) => b.isOn = false,
    onExit: (b) => b.wasOn = false);
final stateOn = State<Lightbulb>('on',
    transitions: [transitionOff],
    onEntry: (b) => b.isOn = true,
    onExit: (b) {
      b.wasOn = true;
      b.cycleCount += 1;
    });
final lightswitch = StateMachine<Lightbulb>(
  'lightswitch',
  [
    stateOff,
    stateOn,
  ],
  onEntry: (bulb) => bulb.masterSwitch = true,
);
