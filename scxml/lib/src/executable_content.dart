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

part of 'statechart.dart';

abstract class ExecutableContent {}

@tag('raise')
class RaiseElement implements ExecutableContent {
  final String event;

  RaiseElement({required this.event});
}

@tag('if')
class IfElement implements ExecutableContent {
  final String cond;
  final List<ExecutableContent> block;

  IfElement(this.cond, this.block);
}

@tag('elseif')
class ElseIfElement implements ExecutableContent {
  final String cond;

  ElseIfElement({required this.cond});
}

@tag('else')
class ElseElement implements ExecutableContent {}

@tag('foreach')
class ForEachElement implements ExecutableContent {
  final String arraySrc;
  final String item;
  final String? index;

  ForEachElement({required this.arraySrc, required this.item, this.index});
}

@tag('log')
class LogElement implements ExecutableContent {
  final String label;
  final String? expr;

  LogElement({this.label = '', this.expr});
}

@tag('assign')
class AssignElement implements ExecutableContent {
  final String location;
  final String? expr;

  AssignElement({required this.location, this.expr});

  // TODO implement children
}

@tag('script')
class ScriptElement implements ExecutableContent {
  final Uri srcUri;
  // TODO Read the raw text
  @textElement
  final String script;

  ScriptElement(this.srcUri, this.script);
}

@tag('send')
class SendElement implements ExecutableContent {
  final String? event;
  @alias('eventexpr')
  final String? eventExpr;
  final Uri? target;
  @alias('targetexpr')
  final String? targetExpr;
  final Uri? type;
  @alias('typeexpr')
  final String? typeExpr;
  final String? id;
  @alias('idlocation')
  final String? idLocation;
  final String? delay;
  @alias('delayexpr')
  final String? delayExpr;
  final String? namelist;

  final List<ParamElement>? parameters;
  final List<ContentElement>? contents;

  SendElement(
      {this.event,
      this.eventExpr,
      this.target,
      this.targetExpr,
      this.type,
      this.typeExpr,
      this.id,
      this.idLocation,
      this.delay,
      this.delayExpr,
      this.namelist,
      this.parameters,
      this.contents});
}

@tag('cancel')
class CancelElement implements ExecutableContent {
  @alias('sendid')
  final String? sendId;
  @alias('sendidexpr')
  final String? sendIdExpr;

  CancelElement({this.sendId, this.sendIdExpr});
}
