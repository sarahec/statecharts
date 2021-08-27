# Statecharts

Why another state machine / statecharts package? I was looking for something akin to the Flutter view hierarchy — 
declarative, immutable, and a good candidate for implementing [SCXML](https://www.w3.org/TR/scxml/).

Let's take a simple [lightswitch example](https://statecharts.dev/what-is-a-statechart.html).

## The data model

```dart
class Lightbulb {
 bool isOn = false;
}
```

## The statechart

```dart
const turnOn = 'turnOn';
const turnOff = 'turnOff';
final res = StateResolver<Lightbulb>();
///
final countedLightswitch = RootState.newRoot<Lightbulb>('lightswitch2', [
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

## Execution

```dart
final engine = await Future.value(lightswitch)
           .then((ls) => Engine.initial<Lightbulb>(ls, bulb));
// Execute an event
await engine.execute(anEvent: 'turnOn');
```

## Disclaimer

This is not an officially supported Google product.
