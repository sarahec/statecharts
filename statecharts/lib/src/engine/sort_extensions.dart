import 'package:meta/meta.dart';
import 'package:statecharts/statecharts.dart';

extension ID<T> on Iterable<State<T>> {
  /// The [id] values of all states sorted by [order]. Used for testing.
  @visibleForTesting
  Iterable<String> get ids => [for (var s in this) s.id ?? '_'];
}

extension Sort<T> on Iterable<State<T>> {
  Iterable<State<T>> get sorted =>
      (toList()..sort((a, b) => a.order.compareTo(b.order)));

  Iterable<State<T>> get reverseSorted =>
      (toList()..sort((a, b) => b.order.compareTo(a.order)));
}

extension SortTransitions<T> on Iterable<Transition<T>> {
  Iterable<Transition<T>> get sorted => (toList()
    ..sort((a, b) => (a.source?.order ?? -1).compareTo(b.source?.order ?? -1)));

  Iterable<Transition<T>> get reverseSorted => (toList()
    ..sort((a, b) => (b.source?.order ?? -1).compareTo(a.source?.order ?? -1)));
}
