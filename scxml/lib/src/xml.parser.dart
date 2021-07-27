// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// ParseMethodGenerator
// **************************************************************************

import 'dart:async';
import 'package:async/async.dart';
import 'package:xml/xml_events.dart';
import 'xml.dart';
import 'dart:core';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:logging/logging.dart';
import 'package:ixp_runtime/ixp_runtime.dart';

const AssignElementName = 'assign';
const CancelElementName = 'cancel';
const ContentElementName = 'content';
const DataElementName = 'data';
const DatamodelElementName = 'datamodel';
const DoneDataElementName = 'donedata';
const ElseElementName = 'else';
const ElseIfElementName = 'elseif';
const FinalStateElementName = 'final';
const FinalizeElementName = 'finalize';
const ForEachElementName = 'foreach';
const HistoryElementName = 'history';
const IfElementName = 'if';
const InitialStateElementName = 'initial';
const InvokeElementName = 'invoke';
const LogElementName = 'log';
const OnEntryElementName = 'onentry';
const OnExitElementName = 'onexit';
const ParallelElementName = 'parallel';
const ParamElementName = 'param';
const RaiseElementName = 'raise';
const SCXMLElementName = 'scxml';
const ScriptElementName = 'script';
const SendElementName = 'send';
const StateElementName = 'state';
const TransitionElementName = 'transition';
final _log = Logger('parser');
Future<AssignElement> extractAssignElement(StreamQueue<XmlEvent> events) async {
  final found = await events.scanTo(startTag(named(AssignElementName)));
  if (!found) {
    throw MissingStartTag(AssignElementName);
  }
  final _assignElement = await events.next as XmlStartElementEvent;
  _log.finest('in assign');

  final location = await _assignElement.attribute<String>('location');
  final expr = await _assignElement.attribute<String>('expr');

  await events.consume(inside(_assignElement));
  return AssignElement(location: location, expr: expr);
}

Future<CancelElement> extractCancelElement(StreamQueue<XmlEvent> events) async {
  final found = await events.scanTo(startTag(named(CancelElementName)));
  if (!found) {
    throw MissingStartTag(CancelElementName);
  }
  final _cancelElement = await events.next as XmlStartElementEvent;
  _log.finest('in cancel');

  final sendId = await _cancelElement.attribute<String>('sendid');
  final sendIdExpr = await _cancelElement.attribute<String>('sendidexpr');

  await events.consume(inside(_cancelElement));
  return CancelElement(sendId: sendId, sendIdExpr: sendIdExpr);
}

Future<ContentElement> extractContentElement(
    StreamQueue<XmlEvent> events) async {
  final found = await events.scanTo(startTag(named(ContentElementName)));
  if (!found) {
    throw MissingStartTag(ContentElementName);
  }
  final _contentElement = await events.next as XmlStartElementEvent;
  _log.finest('in content');

  final expr = await _contentElement.attribute<String>('expr');
  final body = await _contentElement.attribute<String>('body');

  await events.consume(inside(_contentElement));
  return ContentElement(expr: expr, body: body);
}

Future<DataElement> extractDataElement(StreamQueue<XmlEvent> events) async {
  final found = await events.scanTo(startTag(named(DataElementName)));
  if (!found) {
    throw MissingStartTag(DataElementName);
  }
  final _dataElement = await events.next as XmlStartElementEvent;
  _log.finest('in data');

  final id = await _dataElement.attribute<String>('id');
  final src = await _dataElement.attribute<Uri>('src');
  final expr = await _dataElement.attribute<String>('expr');

  await events.consume(inside(_dataElement));
  return DataElement(id: id, src: src, expr: expr);
}

Future<DatamodelElement> extractDatamodelElement(
    StreamQueue<XmlEvent> events) async {
  final found = await events.scanTo(startTag(named(DatamodelElementName)));
  if (!found) {
    throw MissingStartTag(DatamodelElementName);
  }
  final _datamodelElement = await events.next as XmlStartElementEvent;
  _log.finest('in datamodel');

  var data = <DataElement>[];
  while (await events.scanTo(startTag(inside(_datamodelElement)))) {
    final probe = await events.peek as XmlStartElementEvent;
    switch (probe.qualifiedName) {
      case DataElementName:
        data.add(await extractDataElement(events));
        break;
      default:
        probe.logUnknown(expected: DatamodelElementName);
        await events.next;
    }
  }

  await events.consume(inside(_datamodelElement));
  return DatamodelElement(data: data);
}

Future<DoneDataElement> extractDoneDataElement(
    StreamQueue<XmlEvent> events) async {
  final found = await events.scanTo(startTag(named(DoneDataElementName)));
  if (!found) {
    throw MissingStartTag(DoneDataElementName);
  }
  final _doneDataElement = await events.next as XmlStartElementEvent;
  _log.finest('in donedata');

  var content;
  var params = <ParamElement>[];
  while (await events.scanTo(startTag(inside(_doneDataElement)))) {
    final probe = await events.peek as XmlStartElementEvent;
    switch (probe.qualifiedName) {
      case ContentElementName:
        content = await extractContentElement(events);
        break;
      case ParamElementName:
        params.add(await extractParamElement(events));
        break;
      default:
        probe.logUnknown(expected: DoneDataElementName);
        await events.next;
    }
  }

  await events.consume(inside(_doneDataElement));
  return DoneDataElement(content: content, params: params);
}

Future<ElseElement> extractElseElement(StreamQueue<XmlEvent> events) async {
  final found = await events.scanTo(startTag(named(ElseElementName)));
  if (!found) {
    throw MissingStartTag(ElseElementName);
  }
  final _elseElement = await events.next as XmlStartElementEvent;
  _log.finest('in else');

  await events.consume(inside(_elseElement));
  return ElseElement();
}

Future<ElseIfElement> extractElseIfElement(StreamQueue<XmlEvent> events) async {
  final found = await events.scanTo(startTag(named(ElseIfElementName)));
  if (!found) {
    throw MissingStartTag(ElseIfElementName);
  }
  final _elseIfElement = await events.next as XmlStartElementEvent;
  _log.finest('in elseif');

  final cond = await _elseIfElement.attribute<String>('cond');

  await events.consume(inside(_elseIfElement));
  return ElseIfElement(cond: cond);
}

Future<FinalStateElement> extractFinalStateElement(
    StreamQueue<XmlEvent> events) async {
  final found = await events.scanTo(startTag(named(FinalStateElementName)));
  if (!found) {
    throw MissingStartTag(FinalStateElementName);
  }
  final _finalStateElement = await events.next as XmlStartElementEvent;
  _log.finest('in final');

  final id = await _finalStateElement.attribute<String>('id');

  var onEntry;
  var onExit;
  var doneData;
  while (await events.scanTo(startTag(inside(_finalStateElement)))) {
    final probe = await events.peek as XmlStartElementEvent;
    switch (probe.qualifiedName) {
      case OnEntryElementName:
        onEntry = await extractOnEntryElement(events);
        break;
      case OnExitElementName:
        onExit = await extractOnExitElement(events);
        break;
      case DoneDataElementName:
        doneData = await extractDoneDataElement(events);
        break;
      default:
        probe.logUnknown(expected: FinalStateElementName);
        await events.next;
    }
  }

  await events.consume(inside(_finalStateElement));
  return FinalStateElement(
      id: id, onEntry: onEntry, onExit: onExit, doneData: doneData);
}

Future<FinalizeElement> extractFinalizeElement(
    StreamQueue<XmlEvent> events) async {
  final found = await events.scanTo(startTag(named(FinalizeElementName)));
  if (!found) {
    throw MissingStartTag(FinalizeElementName);
  }
  final _finalizeElement = await events.next as XmlStartElementEvent;
  _log.finest('in finalize');

  await events.consume(inside(_finalizeElement));
  return FinalizeElement();
}

Future<ForEachElement> extractForEachElement(
    StreamQueue<XmlEvent> events) async {
  final found = await events.scanTo(startTag(named(ForEachElementName)));
  if (!found) {
    throw MissingStartTag(ForEachElementName);
  }
  final _forEachElement = await events.next as XmlStartElementEvent;
  _log.finest('in foreach');

  final arraySrc = await _forEachElement.attribute<String>('arraySrc');
  final item = await _forEachElement.attribute<String>('item');
  final index = await _forEachElement.attribute<String>('index');

  await events.consume(inside(_forEachElement));
  return ForEachElement(arraySrc: arraySrc, item: item, index: index);
}

Future<HistoryElement> extractHistoryElement(
    StreamQueue<XmlEvent> events) async {
  final found = await events.scanTo(startTag(named(HistoryElementName)));
  if (!found) {
    throw MissingStartTag(HistoryElementName);
  }
  final _historyElement = await events.next as XmlStartElementEvent;
  _log.finest('in history');

  final id = await _historyElement.attribute<String>('id');
  final type =
      await _historyElement.optionalAttribute<String>('type') ?? 'shallow';

  var transition;
  while (await events.scanTo(startTag(inside(_historyElement)))) {
    final probe = await events.peek as XmlStartElementEvent;
    switch (probe.qualifiedName) {
      case TransitionElementName:
        transition = await extractTransitionElement(events);
        break;
      default:
        probe.logUnknown(expected: HistoryElementName);
        await events.next;
    }
  }

  await events.consume(inside(_historyElement));
  return HistoryElement(id: id, type: type, transition: transition);
}

Future<IfElement> extractIfElement(StreamQueue<XmlEvent> events) async {
  final found = await events.scanTo(startTag(named(IfElementName)));
  if (!found) {
    throw MissingStartTag(IfElementName);
  }
  final _ifElement = await events.next as XmlStartElementEvent;
  _log.finest('in if');

  final cond = await _ifElement.attribute<String>('cond');

  var block = <ExecutableContent>[];
  while (await events.scanTo(startTag(inside(_ifElement)))) {
    final probe = await events.peek as XmlStartElementEvent;
    switch (probe.qualifiedName) {
      // No methods found for ExecutableContent

      default:
        probe.logUnknown(expected: IfElementName);
        await events.next;
    }
  }

  await events.consume(inside(_ifElement));
  return IfElement(cond, block);
}

Future<InitialStateElement> extractInitialStateElement(
    StreamQueue<XmlEvent> events) async {
  final found = await events.scanTo(startTag(named(InitialStateElementName)));
  if (!found) {
    throw MissingStartTag(InitialStateElementName);
  }
  final _initialStateElement = await events.next as XmlStartElementEvent;
  _log.finest('in initial');

  var transition;
  while (await events.scanTo(startTag(inside(_initialStateElement)))) {
    final probe = await events.peek as XmlStartElementEvent;
    switch (probe.qualifiedName) {
      case TransitionElementName:
        transition = await extractTransitionElement(events);
        break;
      default:
        probe.logUnknown(expected: InitialStateElementName);
        await events.next;
    }
  }

  await events.consume(inside(_initialStateElement));
  return InitialStateElement(transition: transition);
}

Future<InvokeElement> extractInvokeElement(StreamQueue<XmlEvent> events) async {
  final found = await events.scanTo(startTag(named(InvokeElementName)));
  if (!found) {
    throw MissingStartTag(InvokeElementName);
  }
  final _invokeElement = await events.next as XmlStartElementEvent;
  _log.finest('in invoke');

  final type = await _invokeElement.attribute<Uri>('type');
  final typeExpr = await _invokeElement.attribute<String>('typeexpr');
  final src = await _invokeElement.attribute<Uri>('src');
  final srcExpr = await _invokeElement.attribute<String>('srcexpr');
  final id = await _invokeElement.attribute<String>('id');
  final idLocation = await _invokeElement.attribute<String>('idlocation');
  final nameList = await _invokeElement.attribute<String>('namelist');
  final autoForward = await _invokeElement.attribute<bool>('autoforward',
      convert: Convert.ifEquals('true'));

  var param;
  var finalize;
  var content;
  while (await events.scanTo(startTag(inside(_invokeElement)))) {
    final probe = await events.peek as XmlStartElementEvent;
    switch (probe.qualifiedName) {
      case ParamElementName:
        param = await extractParamElement(events);
        break;
      case FinalizeElementName:
        finalize = await extractFinalizeElement(events);
        break;
      case ContentElementName:
        content = await extractContentElement(events);
        break;
      default:
        probe.logUnknown(expected: InvokeElementName);
        await events.next;
    }
  }

  await events.consume(inside(_invokeElement));
  return InvokeElement(
      type: type,
      typeExpr: typeExpr,
      src: src,
      srcExpr: srcExpr,
      id: id,
      idLocation: idLocation,
      nameList: nameList,
      autoForward: autoForward,
      param: param,
      finalize: finalize,
      content: content);
}

Future<LogElement> extractLogElement(StreamQueue<XmlEvent> events) async {
  final found = await events.scanTo(startTag(named(LogElementName)));
  if (!found) {
    throw MissingStartTag(LogElementName);
  }
  final _logElement = await events.next as XmlStartElementEvent;
  _log.finest('in log');

  final label = await _logElement.optionalAttribute<String>('label') ?? '';
  final expr = await _logElement.attribute<String>('expr');

  await events.consume(inside(_logElement));
  return LogElement(label: label, expr: expr);
}

Future<OnEntryElement> extractOnEntryElement(
    StreamQueue<XmlEvent> events) async {
  final found = await events.scanTo(startTag(named(OnEntryElementName)));
  if (!found) {
    throw MissingStartTag(OnEntryElementName);
  }
  final _onEntryElement = await events.next as XmlStartElementEvent;
  _log.finest('in onentry');

  var body = <ExecutableContent>[];
  while (await events.scanTo(startTag(inside(_onEntryElement)))) {
    final probe = await events.peek as XmlStartElementEvent;
    switch (probe.qualifiedName) {
      // No methods found for ExecutableContent

      default:
        probe.logUnknown(expected: OnEntryElementName);
        await events.next;
    }
  }

  await events.consume(inside(_onEntryElement));
  return OnEntryElement(body);
}

Future<OnExitElement> extractOnExitElement(StreamQueue<XmlEvent> events) async {
  final found = await events.scanTo(startTag(named(OnExitElementName)));
  if (!found) {
    throw MissingStartTag(OnExitElementName);
  }
  final _onExitElement = await events.next as XmlStartElementEvent;
  _log.finest('in onexit');

  var body = <ExecutableContent>[];
  while (await events.scanTo(startTag(inside(_onExitElement)))) {
    final probe = await events.peek as XmlStartElementEvent;
    switch (probe.qualifiedName) {
      // No methods found for ExecutableContent

      default:
        probe.logUnknown(expected: OnExitElementName);
        await events.next;
    }
  }

  await events.consume(inside(_onExitElement));
  return OnExitElement(body);
}

Future<ParallelElement> extractParallelElement(
    StreamQueue<XmlEvent> events) async {
  final found = await events.scanTo(startTag(named(ParallelElementName)));
  if (!found) {
    throw MissingStartTag(ParallelElementName);
  }
  final _parallelElement = await events.next as XmlStartElementEvent;
  _log.finest('in parallel');

  final id = await _parallelElement.attribute<String>('id');

  var onEntry;
  var onExit;
  var transition;
  var history;
  var datamodel;
  var invoke;
  while (await events.scanTo(startTag(inside(_parallelElement)))) {
    final probe = await events.peek as XmlStartElementEvent;
    switch (probe.qualifiedName) {
      case OnEntryElementName:
        onEntry = await extractOnEntryElement(events);
        break;
      case OnExitElementName:
        onExit = await extractOnExitElement(events);
        break;
      case TransitionElementName:
        transition = await extractTransitionElement(events);
        break;
      case HistoryElementName:
        history = await extractHistoryElement(events);
        break;
      case DatamodelElementName:
        datamodel = await extractDatamodelElement(events);
        break;
      case InvokeElementName:
        invoke = await extractInvokeElement(events);
        break;
      default:
        probe.logUnknown(expected: ParallelElementName);
        await events.next;
    }
  }

  await events.consume(inside(_parallelElement));
  return ParallelElement(
      id: id,
      onEntry: onEntry,
      onExit: onExit,
      transition: transition,
      history: history,
      datamodel: datamodel,
      invoke: invoke);
}

Future<ParamElement> extractParamElement(StreamQueue<XmlEvent> events) async {
  final found = await events.scanTo(startTag(named(ParamElementName)));
  if (!found) {
    throw MissingStartTag(ParamElementName);
  }
  final _paramElement = await events.next as XmlStartElementEvent;
  _log.finest('in param');

  final name = await _paramElement.attribute<String>('name');
  final expr = await _paramElement.attribute<String>('expr');
  final location = await _paramElement.attribute<String>('location');

  await events.consume(inside(_paramElement));
  return ParamElement(name: name, expr: expr, location: location);
}

Future<RaiseElement> extractRaiseElement(StreamQueue<XmlEvent> events) async {
  final found = await events.scanTo(startTag(named(RaiseElementName)));
  if (!found) {
    throw MissingStartTag(RaiseElementName);
  }
  final _raiseElement = await events.next as XmlStartElementEvent;
  _log.finest('in raise');

  final event = await _raiseElement.attribute<String>('event');

  await events.consume(inside(_raiseElement));
  return RaiseElement(event: event);
}

Future<SCXMLElement> extractSCXMLElement(StreamQueue<XmlEvent> events) async {
  final found = await events.scanTo(startTag(named(SCXMLElementName)));
  if (!found) {
    throw MissingStartTag(SCXMLElementName);
  }
  final _sCXMLElement = await events.next as XmlStartElementEvent;
  _log.finest('in scxml');

  final initial = await _sCXMLElement.attribute<String>('initial');
  final name = await _sCXMLElement.attribute<String>('name');
  final namespace =
      await _sCXMLElement.optionalAttribute<String>('xmlns') ?? NAMESPACE;
  final version =
      await _sCXMLElement.optionalAttribute<double>('version') ?? 1.0;
  final datamodelType =
      await _sCXMLElement.optionalAttribute<String>('datamodel') ?? 'null';
  final binding =
      await _sCXMLElement.optionalAttribute<String>('binding') ?? 'early';
  final script = await _sCXMLElement.attribute<String>('script');

  var body = <StateBase>[];
  var datamodel;
  while (await events.scanTo(startTag(inside(_sCXMLElement)))) {
    final probe = await events.peek as XmlStartElementEvent;
    switch (probe.qualifiedName) {
      case StateElementName:
        body.add(await extractStateElement(events));
        break;

      case ParallelElementName:
        body.add(await extractParallelElement(events));
        break;

      case FinalStateElementName:
        body.add(await extractFinalStateElement(events));
        break;
      case DatamodelElementName:
        datamodel = await extractDatamodelElement(events);
        break;
      default:
        probe.logUnknown(expected: SCXMLElementName);
        await events.next;
    }
  }

  await events.consume(inside(_sCXMLElement));
  return SCXMLElement(body,
      initial: initial,
      name: name,
      namespace: namespace,
      version: version,
      datamodelType: datamodelType,
      binding: binding,
      datamodel: datamodel,
      script: script);
}

Future<ScriptElement> extractScriptElement(StreamQueue<XmlEvent> events) async {
  final found = await events.scanTo(startTag(named(ScriptElementName)));
  if (!found) {
    throw MissingStartTag(ScriptElementName);
  }
  final _scriptElement = await events.next as XmlStartElementEvent;
  _log.finest('in script');

  final srcUri = await _scriptElement.attribute<Uri>('srcUri');
  var script;
  if (await events.scanTo(textElement(inside(_scriptElement)))) {
    script = (await events.peek as XmlTextEvent).text;
  } else {
    throw MissingText(ScriptElementName, element: _scriptElement);
  }

  await events.consume(inside(_scriptElement));
  return ScriptElement(srcUri, script);
}

Future<SendElement> extractSendElement(StreamQueue<XmlEvent> events) async {
  final found = await events.scanTo(startTag(named(SendElementName)));
  if (!found) {
    throw MissingStartTag(SendElementName);
  }
  final _sendElement = await events.next as XmlStartElementEvent;
  _log.finest('in send');

  final event = await _sendElement.attribute<String>('event');
  final eventExpr = await _sendElement.attribute<String>('eventexpr');
  final target = await _sendElement.attribute<Uri>('target');
  final targetExpr = await _sendElement.attribute<String>('targetexpr');
  final type = await _sendElement.attribute<Uri>('type');
  final typeExpr = await _sendElement.attribute<String>('typeexpr');
  final id = await _sendElement.attribute<String>('id');
  final idLocation = await _sendElement.attribute<String>('idlocation');
  final delay = await _sendElement.attribute<String>('delay');
  final delayExpr = await _sendElement.attribute<String>('delayexpr');
  final namelist = await _sendElement.attribute<String>('namelist');

  var parameters = <ParamElement>[];
  var contents = <ContentElement>[];
  while (await events.scanTo(startTag(inside(_sendElement)))) {
    final probe = await events.peek as XmlStartElementEvent;
    switch (probe.qualifiedName) {
      case ParamElementName:
        parameters.add(await extractParamElement(events));
        break;
      case ContentElementName:
        contents.add(await extractContentElement(events));
        break;
      default:
        probe.logUnknown(expected: SendElementName);
        await events.next;
    }
  }

  await events.consume(inside(_sendElement));
  return SendElement(
      event: event,
      eventExpr: eventExpr,
      target: target,
      targetExpr: targetExpr,
      type: type,
      typeExpr: typeExpr,
      id: id,
      idLocation: idLocation,
      delay: delay,
      delayExpr: delayExpr,
      namelist: namelist,
      parameters: parameters,
      contents: contents);
}

Future<StateElement> extractStateElement(StreamQueue<XmlEvent> events) async {
  final found = await events.scanTo(startTag(named(StateElementName)));
  if (!found) {
    throw MissingStartTag(StateElementName);
  }
  final _stateElement = await events.next as XmlStartElementEvent;
  _log.finest('in state');

  final id = await _stateElement.attribute<String>('id');
  final initial = await _stateElement.attribute<String>('initial');

  var onEntry;
  var onExit;
  var transition;
  var initialState;
  var body = <StateBase>[];
  var history;
  var datamodel;
  var invoke;
  while (await events.scanTo(startTag(inside(_stateElement)))) {
    final probe = await events.peek as XmlStartElementEvent;
    switch (probe.qualifiedName) {
      case OnEntryElementName:
        onEntry = await extractOnEntryElement(events);
        break;
      case OnExitElementName:
        onExit = await extractOnExitElement(events);
        break;
      case TransitionElementName:
        transition = await extractTransitionElement(events);
        break;
      case InitialStateElementName:
        initialState = await extractInitialStateElement(events);
        break;
      case StateElementName:
        body.add(await extractStateElement(events));
        break;

      case ParallelElementName:
        body.add(await extractParallelElement(events));
        break;

      case FinalStateElementName:
        body.add(await extractFinalStateElement(events));
        break;
      case HistoryElementName:
        history = await extractHistoryElement(events);
        break;
      case DatamodelElementName:
        datamodel = await extractDatamodelElement(events);
        break;
      case InvokeElementName:
        invoke = await extractInvokeElement(events);
        break;
      default:
        probe.logUnknown(expected: StateElementName);
        await events.next;
    }
  }

  await events.consume(inside(_stateElement));
  return StateElement(
      id: id,
      initial: initial,
      onEntry: onEntry,
      onExit: onExit,
      transition: transition,
      initialState: initialState,
      body: body,
      history: history,
      datamodel: datamodel,
      invoke: invoke);
}

Future<TransitionElement> extractTransitionElement(
    StreamQueue<XmlEvent> events) async {
  final found = await events.scanTo(startTag(named(TransitionElementName)));
  if (!found) {
    throw MissingStartTag(TransitionElementName);
  }
  final _transitionElement = await events.next as XmlStartElementEvent;
  _log.finest('in transition');

  final event = await _transitionElement.attribute<String>('event');
  final cond = await _transitionElement.attribute<String>('cond');
  final target = await _transitionElement.attribute<String>('target');
  final type =
      await _transitionElement.optionalAttribute<String>('type') ?? 'external';

  await events.consume(inside(_transitionElement));
  return TransitionElement(
      event: event, cond: cond, target: target, type: type);
}
