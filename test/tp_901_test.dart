// TP-901: invio guidato dal profilo, idempotente per event_id.
// Eseguibile con: dart test/tp_901_test.dart
import 'dart:io';
import '../src/domain/phone_number.dart';
import '../src/domain/screening_decision.dart';
import '../src/domain/sms_dispatch.dart';
import '../src/domain/sms_eligibility.dart';
import '../src/domain/user_profile.dart';

void _fail(String msg) {
  stderr.writeln('TP-901 FAILED: $msg');
  exit(1);
}

void _check(bool cond, String msg) {
  if (!cond) _fail(msg);
}

SmsFacts _facts({required bool flag}) {
  final vis = classifyCallerId(const RawCallerId(
      raw: '+393330000030', presentation: Presentation.allowed));
  _check(vis is Visible, 'fixture Visible');
  final dialable = (vis as Visible).number.dialableForSms;
  return SmsFacts(
    visibility: vis,
    dialable: dialable,
    decisionOrigin: DecisionOrigin.unknown,
    blacklistSmsEnabled: flag,
  );
}

void main() {
  // Profilo attivo: invio consentito una sola volta per event_id.
  final profile = UserProfile.defaults().edit(blacklistSmsEnabled: true);
  var calls = 0;
  void sender() {
    calls++;
  }

  var dispatcher = const SmsDispatcher();
  final first = dispatcher.dispatch(
    SmsDispatchEvent(eventId: 'evt-901-a', facts: _facts(flag: profile.blacklistSmsEnabled)),
    sender,
  );
  dispatcher = first.dispatcher;
  _check(first.outcome == SmsSendOutcome.sent, 'profilo attivo deve inviare');
  _check(calls == 1, 'un solo invio atteso');

  // Stesso event_id: duplicate-suppressed, zero nuovi invii.
  final dup = dispatcher.dispatch(
    SmsDispatchEvent(eventId: 'evt-901-a', facts: _facts(flag: profile.blacklistSmsEnabled)),
    sender,
  );
  dispatcher = dup.dispatcher;
  _check(dup.outcome == SmsSendOutcome.duplicateSuppressed, 'duplicato soppresso');
  _check(calls == 1, 'duplicato senza nuovo invio');

  // Profilo con flag OFF su blacklist: skipped senza sender.
  final off = UserProfile.defaults().edit(blacklistSmsEnabled: false);
  final vis = classifyCallerId(const RawCallerId(
      raw: '+393330000002', presentation: Presentation.allowed));
  final dialable = (vis as Visible).number.dialableForSms;
  final bFacts = SmsFacts(
    visibility: vis,
    dialable: dialable,
    decisionOrigin: DecisionOrigin.blacklist,
    blacklistSmsEnabled: off.blacklistSmsEnabled,
  );
  final sk = dispatcher.dispatch(
    SmsDispatchEvent(eventId: 'evt-901-b', facts: bFacts),
    sender,
  );
  dispatcher = sk.dispatcher;
  _check(sk.outcome == SmsSendOutcome.skipped, 'flag OFF deve skippare');
  _check(calls == 1, 'skip senza sender');

  stdout.writeln('TP-901 PASSED: invio da profilo, idempotente, skip su flag OFF');
}
