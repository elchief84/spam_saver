// TP-1103: zero PII in chiaro in logcat, file e crash.
// Eseguibile con: dart test/tp_1103_test.dart
import 'dart:io';
import '../src/domain/pii_redaction.dart';

void _fail(String msg) {
  stderr.writeln('TP-1103 FAILED: $msg');
  exit(1);
}

void _check(bool cond, String msg) {
  if (!cond) _fail(msg);
}

void main() {
  const numbers = [
    '+393330000030',
    '0039 333 000 0031',
    '+39 333-000-0032',
  ];
  for (var i = 0; i < numbers.length; i++) {
    final raw = numbers[i];
    final forLog = scrubForLogcat(raw);
    final forFile = scrubForFile(raw);
    final forCrash = scrubForCrash(raw);
    _check(!hasCleartextDigits(forLog), 'logcat $i con cifre in chiaro: $forLog');
    _check(!hasCleartextDigits(forFile), 'file $i con cifre: $forFile');
    _check(!hasCleartextDigits(forCrash), 'crash $i con cifre: $forCrash');
    _check(isScrubbedClean(forLog), 'logcat $i non pulito');
    _check(isScrubbedClean(forFile), 'file $i non pulito');
    _check(isScrubbedClean(forCrash), 'crash $i non pulito');
    _check(forLog != raw, 'redazione $i deve trasformare');
  }

  // Stringa mista: cifre tutte coperte.
  const mixed = 'chiamata da +393330000030 alle 10:00';
  _check(!hasCleartextDigits(scrubForLogcat(mixed)), 'mista logcat');
  _check(!hasCleartextDigits(scrubForFile(mixed)), 'mista file');
  _check(!hasCleartextDigits(scrubForCrash(mixed)), 'mista crash');

  // Stringa senza cifre resta pulita.
  _check(isScrubbedClean(scrubForLogcat('anonimo')), 'anonimo pulito');

  stdout.writeln('TP-1103 PASSED: zero PII in logcat/file/crash');
}
