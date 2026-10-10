// TP-306: blacklist rifiuta sempre, anche se in rubrica.
// Eseguibile con: dart test/tp_306_test.dart
import 'dart:io';
import '../src/domain/phone_number.dart';
import '../src/domain/screening_decision.dart';
import '../src/domain/sms_eligibility.dart';

void _fail(String msg) {
  stderr.writeln('TP-306 FAILED: $msg');
  exit(1);
}

void _check(bool cond, String msg) {
  if (!cond) _fail(msg);
}

void main() {
  final vis = classifyCallerId(const RawCallerId(
      raw: '+39 333 000 0002', presentation: Presentation.allowed));
  _check(vis is Visible, 'fixture blacklist deve essere Visible');

  final v = decideScreening(ScreeningFacts(
    visibility: vis,
    inContacts: true,
    inWhitelist: false,
    inBlacklist: true,
    roleHeld: true,
  ));
  _check(v.action == ScreeningAction.reject, 'blacklist+rubrica deve rifiutare');
  _check(v.origin == DecisionOrigin.blacklist, 'origine deve essere blacklist');
  _check(v.actuation == ScreeningActuation.disconnect, 'attuazione disconnect');

  // Comportamento SMS secondo SRS-502: flag OFF -> Skipped BLACKLISTED.
  final dialable = (vis as Visible).number.dialableForSms;
  final off = checkSmsEligibility(SmsFacts(
    visibility: vis,
    dialable: dialable,
    decisionOrigin: DecisionOrigin.blacklist,
    blacklistSmsEnabled: false,
  ));
  _check(off is Skipped && off.reason == SmsSkipReason.blacklisted,
      'flag OFF deve dare Skipped BLACKLISTED');
  final on = checkSmsEligibility(SmsFacts(
    visibility: vis,
    dialable: dialable,
    decisionOrigin: DecisionOrigin.blacklist,
    blacklistSmsEnabled: true,
  ));
  _check(on is Eligible, 'flag ON deve dare Eligible');

  stdout.writeln('TP-306 PASSED: blacklist prevale su rubrica; SMS secondo flag');
}
