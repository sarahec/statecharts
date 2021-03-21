import 'package:statecharts/statecharts.dart';
import 'package:test/test.dart';

void main() {
  group('event transition', () {
    final eventTransition = const Transition<int>('a', event: 'onA');

    test('matches event',
        () => expect(eventTransition.matches(anEvent: 'onA'), isTrue));

    test(
        'matches event, any context',
        () => expect(
            eventTransition.matches(anEvent: 'onA', context: 1), isTrue));

    test('doesn\'t match wrong event',
        () => expect(eventTransition.matches(anEvent: 'onB'), isFalse));
  });

  group('event transition + condition', () {
    final conditionalTransition =
        Transition<int>('cond', event: 'onA', condition: (int c) => c == 0);

    test(
        'matches event and condition',
        () => expect(
            conditionalTransition.matches(anEvent: 'onA', context: 0), isTrue));

    test(
        'doesn\'t match correct event, wrong condition',
        () => expect(conditionalTransition.matches(anEvent: 'onA', context: 1),
            isFalse));
    test(
        'doesn\'t match wrong event, correct condition',
        () => expect(conditionalTransition.matches(anEvent: 'onB', context: 0),
            isFalse));

    test('doesn\'t match correct event, missing context',
        () => expect(conditionalTransition.matches(anEvent: 'onA'), isFalse));
  });

  group('non-event transition', () {
    test('matches on condition', () {
      final conditionalTransition =
          NonEventTransition<int>('cond', condition: (int c) => c == 0);
      expect(conditionalTransition.matches(context: 0), isTrue);
      expect(conditionalTransition.matches(context: 1), isFalse);
    });

    test('matches on delay', () {
      final conditionalTransition =
          NonEventTransition<int>('cond', after: Duration(minutes: 1));
      expect(conditionalTransition.matches(elapsedTime: Duration(minutes: 1)),
          isTrue);
      expect(
          conditionalTransition.matches(
              elapsedTime: Duration(milliseconds: 500)),
          isFalse);
    });

    test('ignores event on match', () {
      final conditionalTransition =
          NonEventTransition<int>('cond', condition: (int c) => c == 0);
      expect(
          conditionalTransition.matches(event: 'anything', context: 0), isTrue);
    });
  });
}
