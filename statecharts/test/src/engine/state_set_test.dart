import 'package:statecharts/statecharts.dart';
import 'package:test/test.dart';

import '../examples/lightswitch.dart';

void main() {
  final onState = lightswitch.find('on')!;
  final offState = lightswitch.find('off')!;

  test('new set', () {
    final stateSet = StateSet(lightswitch);
    expect(stateSet, isEmpty);
    expect(stateSet.toList(), isEmpty);
  });

  test('add', () {
    final set = StateSet(lightswitch);
    expect(set.add(onState), isTrue); // true == added
    expect(set.length, equals(1));
    expect(set.contains(onState), isTrue);
    expect(set.contains(offState), isFalse);
    expect(set.contains(lightswitch), isFalse);
  });

  test('remove', () {
    final set = StateSet(lightswitch)..addAll([onState, offState]);
    expect(set.length, equals(2));
    set.remove(onState);
    expect(set.ids, equals(['off']));
    expect(set.length, equals(1));
  });

  test('add duplicate', () {
    final set = StateSet(lightswitch)..add(onState);
    expect(set.length, equals(1));
    expect(set.add(onState), isFalse); // false == duplicate, not added
    expect(set.ids, equals(['on']));
  });

  test('toSet', () {
    final set = StateSet(lightswitch)..add(onState);
    final set2 = set.toSet();
    expect(set, equals(set2));
    expect(set, isNot(same(set2)));
  });

  test('sorting', () {
    assert(onState.order > offState.order);
    final set = StateSet(lightswitch)..add(onState);
    expect(set.ids, equals(['on']));
    set.add(offState);
    expect(set.ids, equals(['off', 'on']));
    expect(set.toList(), equals([offState, onState]));
  });

  group('extensions', () {
    final set = StateSet(lightswitch)
      ..add(lightswitch)
      ..add(onState);

    test('ancestors',
        () => expect(set.ancestors(onState), equals([lightswitch])));

    test('descendents',
        () => expect(set.descendents(lightswitch), equals([onState])));
  });
}
