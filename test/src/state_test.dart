import 'package:test/test.dart';
import 'package:statecharts/statecharts.dart';

void main() {
  group('lightswitch', () {
    final lightswitch = const StateMachine('lightswitch', [
      State('off',
          isInitial: true, transitions: [Transition('on', event: 'on')]),
      State('on', transitions: [Transition('off', event: 'off')]),
    ]);

    test('initial state', () {
      expect(lightswitch.initialState.id, equals('off'));
    });
  });
}
