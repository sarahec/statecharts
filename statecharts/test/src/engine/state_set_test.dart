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

  test('add element', () {
    final set = StateSet(lightswitch)..add(onState);
    expect(set.length, equals(1));
    expect(set.contains(onState), isTrue);
    expect(set.contains(offState), isFalse);
    expect(set.contains(lightswitch), isFalse);
  });

  test('remove element', () {
    final set = StateSet(lightswitch)..addAll([onState, offState]);
    expect(set.length, equals(2));
    set.remove(onState);
    expect(set.ids, equals(['off']));
    expect(set.length, equals(1));
  });

  test('ignores duplicate additions', () {
    final set = StateSet(lightswitch)..add(onState);
    expect(set.length, equals(1));
    set.add(onState);
    expect(set.ids, equals(['on']));
  });

  test('sorts elements', () {
    assert(onState.order > offState.order);
    final set = StateSet(lightswitch)..add(onState);
    expect(set.ids, equals(['on']));
    set.add(offState);
    expect(set.ids, equals(['off', 'on']));
    expect(set.toList(), equals([offState, onState]));
  });

  test('copies set', () {
    final set = StateSet(lightswitch)..add(onState);
    final set2 = set.toSet();
    expect(set, equals(set2));
    expect(set, isNot(same(set2)));
  });
}
