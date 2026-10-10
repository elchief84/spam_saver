// TP-902: doppio evento stesso event_id => 1 solo invio, secondo duplicate-suppressed.
// Eseguibile con: dart test/tp_902_test.dart
import 'dart:io';
import '../src/domain/phone_number.dart';
import '../src/domain/screening_decision.dart';
import '../src/domain/sms_dispatch.dart';
import '../src/domain/sms_eligibility.dart';

void _fail(String msg) {
  stderr.writeln('TP-902 FAILED: $msg');
  exit(1);
}

void _check(bool cond, String msg) {
  if (!cond) _fail(msg);
}

void main() {
  final vis = classifyCallerId(const RawCallerId(
      raw: '+393330000030', presentation: Presentation.allowed));
  _check(vis is Visible, 'fixture deve essere Visible');
  final dialable = (vis as Visible).number.dialableForSms;

  final facts = SmsFacts(
    visibility: vis,
    dialable: dialable,
    decisionOrigin: DecisionOrigin.unknown,
    blacklistSmsEnabled: true,
  );

  var senderCalls = 0;
  void sender() {
    senderCalls++;
  }

  var dispatcher = const SmsDispatcher();
  const eventId = 'evt-902-dup';

  final first = dispatcher.dispatch(
    SmsDispatchEvent(eventId: eventId, facts: facts),
    sender,
  );
  dispatcher = first.dispatcher;
  _check(first.outcome == SmsSendOutcome.sent, 'primo evento deve dare sent');
  _check(senderCalls == 1, 'dopo primo evento 1 invio atteso, trovati $senderCalls');

  final second = dispatcher.dispatch(
    SmsDispatchEvent(eventId: eventId, facts: facts),
    sender,
  );
  dispatcher = second.dispatcher;
  _check(second.outcome == SmsSendOutcome.duplicateSuppressed,
      'doppio event_id deve dare duplicate-suppressed, trovato ${second.outcome}');
  _check(senderCalls == 1,
      'doppio evento deve dare 1 solo invio, chiamate $senderCalls');
  _check(dispatcher.senderCalls == 1, 'dispatcher deve contare 1 solo invio');
  _check(dispatcher.seenCount == 1, 'un solo event_id distinto atteso');

  // Terzo invio con event_id diverso deve inviare di nuovo.
  final third = dispatcher.dispatch(
    SmsDispatchEvent(eventId: 'evt-902-altro', facts: facts),
    sender,
  );
  dispatcher = third.dispatcher;
  _check(third.outcome == SmsSendOutcome.sent, 'event_id nuovo deve dare sent');
  _check(senderCalls == 2, 'event_id diverso deve inviare, chiamate $senderCalls');

  stdout.writeln('TP-902 PASSED: doppio event_id => 1 invio, duplicate-suppressed');
}
