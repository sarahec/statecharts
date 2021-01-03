import 'package:test/test.dart';
import 'package:statecharts/statecharts.dart';

void main() {
  test('xml ...', () async {
    var finalState = State(id: 'final');
    expect(finalState.isAtomic, isTrue);
  });
}
