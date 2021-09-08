# Statecharts

Why another state machine / statecharts package? I was looking for something akin to the Flutter view hierarchy --
declarative, immutable, and a good candidate for implementing [SCXML](https://www.w3.org/TR/scxml/).

## Example

Let's take a simple [lightswitch example](https://statecharts.dev/what-is-a-statechart.html).

### The data model

```dart
class Lightbulb {
 bool isOn = false;
}
```

### The statechart

```dart
const turnOn = 'turnOn';
const turnOff = 'turnOff';
final res = StateResolver<Lightbulb>();

final lightswitch = RootState.newRoot<Lightbulb>('lightswitch2', [
 State<Lightbulb>('off',
     transitions: [
       res.transition(
           targets: ['on'],
           event: turnOn,
     ],
     onEntry: (b, _) => b!.isOn = false),
 State<Lightbulb>('on',
     transitions: [
       res.transition(targets: ['off'], event: turnOff),
     ],
     onEntry: (b, _) => b!.isOn = true),
]);
```

### Execution

```dart
final engine = await Future.value(lightswitch)
           .then((ls) => Engine.initial<Lightbulb>(ls, bulb));
// Execute an event
await engine.execute(anEvent: 'turnOn');
```

## Example with conditional transitions

Add a counter field.

```dart
class Lightbulb {
 bool isOn = false;
 int cycleCount = 0;
}
```

Test this field in the off -> on transition.

Increment this field on the on -> off transition.

```dart
const turnOn = 'turnOn';
const turnOff = 'turnOff';
final res = StateResolver<Lightbulb>();

final countedLightswitch = RootState.newRoot<Lightbulb>('lightswitch2', [
  State<Lightbulb>('off',
      transitions: [
        res.transition(
            targets: ['on'],
            event: turnOn,
            condition: (b) => b.cycleCount < 10),
      ],
      onEntry: (b, _) => b!.isOn = false),
  State<Lightbulb>('on',
      transitions: [
        res.transition(targets: ['off'], event: turnOff),
      ],
      onEntry: (b, _) => b!.isOn = true,
      onExit: (b, _) {
        b!.cycleCount += 1;
      }),
]);
```

```dart
final engine = await Future.value(countedLightswitch)
           .then((ls) => Engine.initial<Lightbulb>(ls, bulb));
// Execute an event
await engine.execute(anEvent: 'turnOn');
```

## Generating code coverage

Generate `coverage/lcov.info`.

```sh
tools/coverage.sh
```

View in the LCOV tool of your choice.

## Disclaimer

This is not an officially supported Google product.
