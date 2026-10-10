// TP-305: mai SMS a short code / alfanumerici / non composti.
// Eseguibile con: dart test/tp_305_test.dart
import 'dart:io';
import '../src/domain/phone_number.dart';
import '../src/domain/screening_decision.dart';
import '../src/domain/sms_eligibility.dart';

void _fail(String msg) {
  stderr.writeln('TP-305 FAILED: $msg');
  exit(1);
}

void _check(bool cond, String msg) {
  if (!cond) _fail(msg);
}

void main() {
  final inputs = <String, bool>{
    '40400': false,
    'BANCA': false,
    '+39 ABC': false,
    '': false,
    '+393330000030': true,
  };
  inputs.forEach((input, wantDialable) {
    final got = isSmsDialable(input);
    _check(got == wantDialable,
        'isSmsDialable("$input") atteso $wantDialable, trovato $got');
    final vis = classifyCallerId(
        RawCallerId(raw: input, presentation: Presentation.allowed));
    if (wantDialable) {
      _check(vis is Visible && vis.number.dialableForSms,
          '"$input" deve essere Visible dialable');
      final e = checkSmsEligibility(SmsFacts(
        visibility: vis,
        dialable: true,
        decisionOrigin: DecisionOrigin.unknown,
        blacklistSmsEnabled: false,
      ));
      _check(e is Eligible, '"$input" deve essere Eligible');
    } else {
      final dialable = vis is Visible ? vis.number.dialableForSms : false;
      _check(!dialable, '"$input" non deve essere dialable');
      final e = checkSmsEligibility(SmsFacts(
        visibility: vis,
        dialable: dialable,
        decisionOrigin: DecisionOrigin.unknown,
        blacklistSmsEnabled: false,
      ));
      _check(e is Skipped, '"$input" deve essere Skipped');
      if (vis is Hidden || vis is EmptyNumber) {
        _check(e is Skipped && e.reason == SmsSkipReason.hidden,
            '"$input" motivo HIDDEN');
      } else {
        _check(e is Skipped && e.reason == SmsSkipReason.nonDialable,
            '"$input" motivo NON_DIALABLE');
      }
    }
  });
  stdout.writeln('TP-305 PASSED: 5/5 classificati, solo +393330000030 dialable');
}
