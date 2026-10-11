// TP-1104: canarino mai in match con dati reali o redatti.
// Eseguibile con: dart test/tp_1104_test.dart
import 'dart:io';
import '../src/domain/pii_redaction.dart';

void _fail(String msg) {
  stderr.writeln('TP-1104 FAILED: $msg');
  exit(1);
}

void _check(bool cond, String msg) {
  if (!cond) _fail(msg);
}

void main() {
  // Canarino riconoscibile e senza cifre.
  _check(piiCanary.isNotEmpty, 'canarino vuoto');
  _check(!hasCleartextDigits(piiCanary), 'canarino non deve avere cifre');
  _check(isCanary(piiCanary), 'canarino deve riconoscersi');

  // Mai match con numeri reali.
  const reals = ['+393330000030', '3330000001', 'BANCA', 'anon'];
  for (final r in reals) {
    _check(!isCanary(r), 'reale $r non deve essere canarino');
    _check(!isCanary(redactPii(r)), 'redatto $r non deve essere canarino');
    _check(!redactPii(r).contains(piiCanary), 'redatto non contiene canarino');
  }

  // Redatti mai uguali al canarino.
  for (final r in reals) {
    _check(scrubForLogcat(r) != piiCanary, 'log $r != canarino');
    _check(scrubForFile(r) != piiCanary, 'file $r != canarino');
    _check(scrubForCrash(r) != piiCanary, 'crash $r != canarino');
  }

  // Il canarino redatto resta se stesso (nessuna cifra da coprire).
  _check(redactPii(piiCanary) == piiCanary, 'canarino stabile in redazione');

  stdout.writeln('TP-1104 PASSED: canarino mai in match ($piiCanary)');
}
