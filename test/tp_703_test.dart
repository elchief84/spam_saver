// TP-703: precedenza blacklist > pass(contatti/whitelist) > reject.
// Eseguibile con: dart test/tp_703_test.dart
import 'dart:io';
import '../src/domain/phone_number.dart';
import '../src/domain/screening_decision.dart';

void _fail(String msg) {
  stderr.writeln('TP-703 FAILED: $msg');
  exit(1);
}

void _check(bool cond, String msg) {
  if (!cond) _fail(msg);
}

void main() {
  final known = classifyCallerId(const RawCallerId(
      raw: '+393330000030', presentation: Presentation.allowed));
  final anon = classifyCallerId(const RawCallerId(
      raw: '+393330000030', presentation: Presentation.restricted));

  ScreeningVerdict d({
    required PhoneNumberResult vis,
    bool c = false,
    bool w = false,
    bool b = false,
  }) =>
      decideScreening(ScreeningFacts(
        visibility: vis,
        inContacts: c,
        inWhitelist: w,
        inBlacklist: b,
        roleHeld: true,
      ));

  final v1 = d(vis: known, c: true, b: true);
  _check(v1.action == ScreeningAction.reject &&
      v1.origin == DecisionOrigin.blacklist, 'blacklist+rubrica -> reject/blacklist');

  final v2 = d(vis: known, w: true, b: true);
  _check(v2.action == ScreeningAction.reject &&
      v2.origin == DecisionOrigin.blacklist, 'blacklist+whitelist -> reject/blacklist');

  final v3 = d(vis: known, c: true);
  _check(v3.action == ScreeningAction.pass &&
      v3.origin == DecisionOrigin.contacts, 'rubrica sola -> pass/contacts');

  final v4 = d(vis: known, w: true);
  _check(v4.action == ScreeningAction.pass &&
      v4.origin == DecisionOrigin.whitelist, 'whitelist sola -> pass/whitelist');

  final v5 = d(vis: known);
  _check(v5.action == ScreeningAction.reject &&
      v5.origin == DecisionOrigin.unknown, 'sconosciuto -> reject/unknown');

  final v6 = d(vis: anon);
  _check(v6.action == ScreeningAction.pass &&
      v6.origin == DecisionOrigin.anonymous, 'anonimo -> pass/anonymous');

  stdout.writeln('TP-703 PASSED: 6/6 precedenza conforme');
}
