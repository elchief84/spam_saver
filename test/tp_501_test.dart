// TP-501: invio eleggibile chiama il sender esattamente una volta.
// Eseguibile con: dart test/tp_501_test.dart
import 'dart:io';
import '../src/domain/phone_number.dart';
import '../src/domain/screening_decision.dart';
import '../src/domain/sms_dispatch.dart';
import '../src/domain/sms_eligibility.dart';

void _fail(String msg) {
  stderr.writeln('TP-501 FAILED: $msg');
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
  _check(dialable, 'fixture deve essere dialable');

  // Sconosciuto con flag ON: eleggibile.
  final facts = SmsFacts(
    visibility: vis,
    dialable: dialable,
    decisionOrigin: DecisionOrigin.unknown,
    blacklistSmsEnabled: true,
  );
  _check(checkSmsEligibility(facts) is Eligible, 'fixture deve essere Eligible');

  var senderCalls = 0;
  void sender() {
    senderCalls++;
  }

  var dispatcher = const SmsDispatcher();
  final res = dispatcher.dispatch(
    SmsDispatchEvent(eventId: 'evt-501-1', facts: facts),
    sender,
  );
  dispatcher = res.dispatcher;
  _check(res.outcome == SmsSendOutcome.sent, 'invio eleggibile deve dare sent');
  _check(res.skipReason == null, 'sent non deve avere skipReason');
  _check(senderCalls == 1, 'sender deve essere chiamato 1 volta, trovate $senderCalls');
  _check(dispatcher.senderCalls == 1, 'dispatcher deve contare 1 invio');
  _check(dispatcher.hasSeen('evt-501-1'), 'event_id deve essere registrato');
  _check(dispatcher.seenCount == 1, 'atteso 1 event_id visto');

  stdout.writeln('TP-501 PASSED: eleggibile => 1 invio via sender');
}
