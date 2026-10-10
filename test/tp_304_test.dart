// TP-304: hidden/vuoti passano, mai SMS.
// Eseguibile con: dart test/tp_304_test.dart
import 'dart:io';
import '../src/domain/phone_number.dart';
import '../src/domain/screening_decision.dart';
import '../src/domain/sms_eligibility.dart';

void _fail(String msg) {
  stderr.writeln('TP-304 FAILED: $msg');
  exit(1);
}

void _check(bool cond, String msg) {
  if (!cond) _fail(msg);
}

void main() {
  final cases = <String, PhoneNumberResult>{
    'restricted': classifyCallerId(const RawCallerId(
        raw: '+393330000030', presentation: Presentation.restricted)),
    'unknown': classifyCallerId(const RawCallerId(
        raw: '+393330000030', presentation: Presentation.unknown)),
    'empty': classifyCallerId(
        const RawCallerId(raw: '', presentation: Presentation.allowed)),
    'null': classifyCallerId(
        const RawCallerId(raw: null, presentation: Presentation.allowed)),
  };
  var n = 0;
  cases.forEach((label, vis) {
    n++;
    final v = decideScreening(ScreeningFacts(
      visibility: vis,
      inContacts: false,
      inWhitelist: false,
      inBlacklist: false,
      roleHeld: true,
    ));
    _check(v.action == ScreeningAction.pass, '$label deve passare');
    _check(v.origin == DecisionOrigin.anonymous, '$label origine anonymous');
    final e = checkSmsEligibility(SmsFacts(
      visibility: vis,
      dialable: false,
      decisionOrigin: DecisionOrigin.unknown,
      blacklistSmsEnabled: true,
    ));
    _check(e is Skipped && e.reason == SmsSkipReason.hidden,
        '$label SMS deve essere Skipped HIDDEN');
  });
  _check(n == 4, 'attesi 4 casi, trovati $n');
  stdout.writeln('TP-304 PASSED: 4/4 pass-through, zero SMS');
}
