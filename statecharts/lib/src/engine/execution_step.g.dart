// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'execution_step.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ExecutionStep<T> extends ExecutionStep<T> {
  @override
  final ExecutionStep<T>? priorStep;
  @override
  final State<T> root;
  @override
  final BuiltSet<State<T>> selections;
  @override
  final Iterable<Transition<T>>? transitions;
  Set<State<T>>? __activeStates;
  Iterable<State<T>>? __entryStates;
  Iterable<State<T>>? __exitStates;
  BuiltMap<String, Iterable<State<T>>>? __history;
  bool? __isChanged;

  factory _$ExecutionStep([void Function(ExecutionStepBuilder<T>)? updates]) =>
      (new ExecutionStepBuilder<T>()..update(updates)).build();

  _$ExecutionStep._(
      {this.priorStep,
      required this.root,
      required this.selections,
      this.transitions})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(root, 'ExecutionStep', 'root');
    BuiltValueNullFieldError.checkNotNull(
        selections, 'ExecutionStep', 'selections');
    if (T == dynamic) {
      throw new BuiltValueMissingGenericsError('ExecutionStep', 'T');
    }
  }

  @override
  Set<State<T>> get activeStates => __activeStates ??= super.activeStates;

  @override
  Iterable<State<T>> get entryStates => __entryStates ??= super.entryStates;

  @override
  Iterable<State<T>> get exitStates => __exitStates ??= super.exitStates;

  @override
  BuiltMap<String, Iterable<State<T>>> get history =>
      __history ??= super.history;

  @override
  bool get isChanged => __isChanged ??= super.isChanged;

  @override
  ExecutionStep<T> rebuild(void Function(ExecutionStepBuilder<T>) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ExecutionStepBuilder<T> toBuilder() =>
      new ExecutionStepBuilder<T>()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ExecutionStep &&
        priorStep == other.priorStep &&
        root == other.root &&
        selections == other.selections &&
        transitions == other.transitions;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc($jc($jc(0, priorStep.hashCode), root.hashCode),
            selections.hashCode),
        transitions.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('ExecutionStep')
          ..add('priorStep', priorStep)
          ..add('root', root)
          ..add('selections', selections)
          ..add('transitions', transitions))
        .toString();
  }
}

class ExecutionStepBuilder<T>
    implements Builder<ExecutionStep<T>, ExecutionStepBuilder<T>> {
  _$ExecutionStep<T>? _$v;

  ExecutionStepBuilder<T>? _priorStep;
  ExecutionStepBuilder<T> get priorStep =>
      _$this._priorStep ??= new ExecutionStepBuilder<T>();
  set priorStep(ExecutionStepBuilder<T>? priorStep) =>
      _$this._priorStep = priorStep;

  State<T>? _root;
  State<T>? get root => _$this._root;
  set root(State<T>? root) => _$this._root = root;

  SetBuilder<State<T>>? _selections;
  SetBuilder<State<T>> get selections =>
      _$this._selections ??= new SetBuilder<State<T>>();
  set selections(SetBuilder<State<T>>? selections) =>
      _$this._selections = selections;

  Iterable<Transition<T>>? _transitions;
  Iterable<Transition<T>>? get transitions => _$this._transitions;
  set transitions(Iterable<Transition<T>>? transitions) =>
      _$this._transitions = transitions;

  ExecutionStepBuilder();

  ExecutionStepBuilder<T> get _$this {
    final $v = _$v;
    if ($v != null) {
      _priorStep = $v.priorStep?.toBuilder();
      _root = $v.root;
      _selections = $v.selections.toBuilder();
      _transitions = $v.transitions;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ExecutionStep<T> other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$ExecutionStep<T>;
  }

  @override
  void update(void Function(ExecutionStepBuilder<T>)? updates) {
    if (updates != null) updates(this);
  }

  @override
  _$ExecutionStep<T> build() {
    _$ExecutionStep<T> _$result;
    try {
      _$result = _$v ??
          new _$ExecutionStep<T>._(
              priorStep: _priorStep?.build(),
              root: BuiltValueNullFieldError.checkNotNull(
                  root, 'ExecutionStep', 'root'),
              selections: selections.build(),
              transitions: transitions);
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'priorStep';
        _priorStep?.build();

        _$failedField = 'selections';
        selections.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'ExecutionStep', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
