// TP-101: 2 chiamate allo stesso numero = 2 righe di registro.
// Eseguibile con: dart test/tp_101_test.dart
import 'dart:io';
import '../src/domain/reject_log.dart';

void _fail(String msg) {
  stderr.writeln('TP-101 FAILED: $msg');
  exit(1);
}

void _check(bool cond, String msg) {
  if (!cond) _fail(msg);
}

void main() {
  var log = const RejectLog();
  _check(log.length == 0, 'registro iniziale deve essere vuoto');

  log = log.logRejectedCall(
      normalizedNumber: '+393330000030', templateRef: 'default-v1');
  _check(log.length == 1, 'una chiamata deve dare 1 riga');

  log = log.logRejectedCall(
      normalizedNumber: '+393330000030', templateRef: 'default-v1');
  _check(log.length == 2,
      'due chiamate stesso numero devono dare 2 righe, trovate ${log.length}');
  _check(log.entries[0].numberKey == log.entries[1].numberKey,
      'entrambe le righe devono riferire lo stesso numero');
  _check(log.entries[0].numberKey == '+393330000030',
      'chiave numero attesa +393330000030');

  stdout.writeln('TP-101 PASSED: 2 chiamate stesso numero = 2 righe');
}
