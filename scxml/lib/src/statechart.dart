// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:ixp_runtime/annotations.dart';
import 'package:logging/logging.dart';

part 'executable_content.dart';

const NAMESPACE = 'http://www.w3.org/2005/07/scxml';

final _log = Logger('SCXML');

abstract class StateBase {
  @alias('onentry')
  final OnEntryElement? onEntry;
  @alias('onexit')
  final OnExitElement? onExit;

  bool get isAtomic;

  StateBase({required this.onEntry, required this.onExit});
}

@tag('scxml')
class SCXMLElement {
  final String? initial;
  final String? name;
  @alias('xmlns')
  final String namespace;
  final double version;
  @alias('datamodel')
  final String datamodelType;
  final String binding;

  final List<StateBase> body;
  final DatamodelElement? datamodel;
  final String? script;

  SCXMLElement(this.body,
      {this.initial,
      this.name,
      this.namespace = NAMESPACE,
      this.version = 1.0,
      this.datamodelType = 'null', // for now
      this.binding = 'early', // enum: early, late
      this.datamodel,
      this.script})
      : assert(version == 1.0, 'Version 1.0 required'),
        assert(namespace == NAMESPACE, 'xmlns attribute'),
        assert(body.isNotEmpty);
}

@tag('onentry')
class OnEntryElement {
  final List<ExecutableContent> body;

  OnEntryElement(this.body);
}

@tag('onexit')
class OnExitElement {
  final List<ExecutableContent> body;

  OnExitElement(this.body);
}

abstract class ParallelChild {}

@tag('state')
class StateElement extends StateBase with ParallelChild {
  final String? id;
  final String? initial;
  final TransitionElement? transition;

  @alias('initial')
  final InitialStateElement? initialState;
  final List<StateBase>? body;
  final HistoryElement? history;

  final DatamodelElement? datamodel;
  final InvokeElement? invoke;

  StateElement(
      {this.id,
      this.initial,
      onEntry,
      onExit,
      this.transition,
      this.initialState,
      this.body,
      this.history,
      this.datamodel,
      this.invoke})
      : super(onEntry: onEntry, onExit: onExit);

  @override
  bool get isAtomic => body?.isNotEmpty ?? true;
}

@tag('parallel')
class ParallelElement extends StateBase with ParallelChild {
  final String? id;
  final TransitionElement? transition;
  List<ParallelChild>? body;
  final HistoryElement? history;
  final DatamodelElement? datamodel;
  final InvokeElement? invoke;

  @override
  bool get isAtomic => false;

  ParallelElement(
      {this.id,
      onEntry,
      onExit,
      this.transition,
      this.history,
      this.datamodel,
      this.invoke})
      : super(onEntry: onEntry, onExit: onExit);
}

@tag('initial')
class InitialStateElement {
  final TransitionElement? transition;

  InitialStateElement({required this.transition});
}

@tag('final')
class FinalStateElement extends StateBase {
  final String? id;

  @alias('donedata')
  final DoneDataElement? doneData;

  FinalStateElement({this.id, onEntry, onExit, this.doneData})
      : super(onEntry: onEntry, onExit: onExit);

  @override
  bool get isAtomic => true;
}

@tag('transition')
class TransitionElement {
  final String? event;
  final String? cond;
  final String? target;
  final String type;

  TransitionElement(
      {this.event, this.cond, this.target, this.type = 'external'});
  List<ExecutableContent>? children;
}

@tag('donedata')
class DoneDataElement {
  final ContentElement? content;
  final List<ParamElement>? params;

  DoneDataElement({this.content, this.params});
}

@tag('param')
class ParamElement {
  final String name;
  final String? expr;
  final String? location;

  ParamElement({required this.name, this.expr, this.location});
}

@tag('content')
class ContentElement {
  final String? expr;
  // TODO Define @xml() annotation
  final String? body;

  ContentElement({this.expr, this.body});
}

@tag('datamodel')
class DatamodelElement {
  final List<DataElement>? data;

  DatamodelElement({this.data});
}

@tag('data')
class DataElement {
  final String id;
  final Uri? src;
  final String? expr;

  // TODO Implement contents

  DataElement({required this.id, this.src, this.expr});
}

@tag('invoke')
class InvokeElement {
  final Uri? type;
  @alias('typeexpr')
  final String? typeExpr;
  final Uri? src;
  @alias('srcexpr')
  final String? srcExpr;
  final String? id;
  @alias('idlocation')
  final String? idLocation;
  @alias('namelist')
  final String? nameList;
  @ifEquals('true')
  @alias('autoforward')
  final bool? autoForward;

  final ParamElement? param;
  final FinalizeElement? finalize;
  final ContentElement? content;

  InvokeElement(
      {this.type,
      this.typeExpr,
      this.src,
      this.srcExpr,
      this.id,
      this.idLocation,
      this.nameList,
      this.autoForward,
      this.param,
      this.finalize,
      this.content});
}

@tag('finalize')
class FinalizeElement {}

@tag('history')
class HistoryElement {
  final String? id;
  final String type; // enum: 'deep' or 'shallow'
  final TransitionElement? transition;

  HistoryElement({this.id, this.type = 'shallow', required this.transition});
}
