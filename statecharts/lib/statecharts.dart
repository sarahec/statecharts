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

/// # Extensible statechart library.
///
/// This contains the tools to build an executable
/// [statechart](https://statecharts.dev), essentially a state machine with
/// nested substates and well-defined behaviors.
///
/// Each statechart is a tree with a [RootState] and one or more substates (
/// [State]). Each [State] can contain [Transition] objects that are triggered
/// by a message (event) or by a timer.
///
/// Each statechart may also have an associated data structure (`context`)
/// that can be altered by the state machine.
///
/// Let's take a simple [lightswitch example](https://statecharts.dev/what-is-a-statechart.html).
///
/// ## The data model
///
/// ```
/// class Lightbulb {
///  bool isOn = false;
/// }
/// ```
///
/// ## The statechart
///
/// ```
/// const turnOn = 'turnOn';
/// const turnOff = 'turnOff';
///
/// final countedLightswitch = RootState.newRoot<Lightbulb>('lightswitch2', [
///  State<Lightbulb>('off',
///      transitions: [
///        Transition(
///            targets: ['on'],
///            event: turnOn,
///      ],
///      onEntry: (b, _) => b!.isOn = false),
///  State<Lightbulb>('on',
///      transitions: [
///        Transition(targets: ['off'], event: turnOff),
///      ],
///      onEntry: (b, _) => b!.isOn = true),
/// ]);
/// ```
///
/// ## Execution
///
/// ```
/// final engine = Engine<Lightbulb>(lightswitch, bulb);
/// // Execute an event
/// engine.execute(anEvent: 'turnOn');
/// ```

library statecharts;

export 'src/engine/engine.dart';
export 'src/engine/engine_callback.dart';
export 'src/engine/execution_step.dart';
export 'src/engine/execution_step_base.dart';
export 'src/engine/sort_extensions.dart';
export 'src/engine/state_set.dart';
export 'src/engine/state_tree.dart';
export 'src/statechart/state.dart';
export 'src/statechart/history_state.dart';
export 'src/statechart/transition.dart';
export 'src/statechart/typedefs.dart';
