// TP-502: flag OFF su blacklist => skipped senza chiamata al sender.
// Eseguibile con: dart test/tp_502_test.dart
import 'dart:io';
import '../src/domain/phone_number.dart';
import '../src/domain/screening_decision.dart';
import '../src/domain/sms_dispatch.dart';
import '../src/domain/sms_eligibility.dart';

void _fail(String msg) {
  stderr.writeln('TP-502 FAILED: $msg');
  exit(1);
}

void _check(bool cond, String msg) {
  if (!cond) _fail(msg);
}

void main() {
  final vis = classifyCallerId(const RawCallerId(
      raw: '+393330000002', presentation: Presentation.allowed));
  _check(vis is Visible, 'fixture blacklist deve essere Visible');
  final dialable = (vis as Visible).number.dialableForSms;
  _check(dialable, 'fixture deve restare dialable (skip da policy, non da numero)');

  // Origine blacklist con flag OFF: gate Skipped BLACKLISTED.
  final facts = SmsFacts(
    visibility: vis,
    dialable: dialable,
    decisionOrigin: DecisionOrigin.blacklist,
    blacklistSmsEnabled: false,
  );
  final gate = checkSmsEligibility(facts);
  _check(gate is Skipped && gate.reason == SmsSkipReason.blacklisted,
      'flag OFF deve dare Skipped blacklisted');

  var senderCalls = 0;
  void sender() {
    senderCalls++;
  }

  var dispatcher = const SmsDispatcher();
  final res = dispatcher.dispatch(
    SmsDispatchEvent(eventId: 'evt-502-1', facts: facts),
    sender,
  );
  dispatcher = res.dispatcher;
  _check(res.outcome == SmsSendOutcome.skipped, 'flag OFF deve dare skipped');
  _check(res.skipReason == SmsSkipReason.blacklisted,
      'motivo atteso blacklisted, trovato ${res.skipReason}');
  _check(senderCalls == 0,
      'sender non deve essere chiamato con flag OFF, chiamate $senderCalls');
  _check(dispatcher.senderCalls == 0, 'dispatcher deve contare 0 invii');
  _check(dispatcher.hasSeen('evt-502-1'), 'event_id skippato va comunque registrato');

  stdout.writeln('TP-502 PASSED: flag OFF blacklist => skipped, 0 chiamate sender');
}
