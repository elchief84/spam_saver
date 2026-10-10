// TP-701: le righe portano template_ref come hash, mai il body.
// Eseguibile con: dart test/tp_701_test.dart
import 'dart:io';
import '../src/domain/reject_log.dart';

void _fail(String msg) {
  stderr.writeln('TP-701 FAILED: $msg');
  exit(1);
}

void _check(bool cond, String msg) {
  if (!cond) _fail(msg);
}

void main() {
  const ref = 'default-v1';
  const body = 'Non posso rispondere ora. Ti richiamero il prima possibile.';

  // Hash deterministico e di forma attesa (8 cifre esadecimali).
  _check(hashTemplateRef(ref) == hashTemplateRef(ref), 'hash deve essere deterministico');
  final hash = hashTemplateRef(ref);
  _check(RegExp(r'^[0-9a-f]{8}$').hasMatch(hash), 'hash atteso in forma 8 hex, trovato $hash');
  _check(hashTemplateRef('default-v1') != hashTemplateRef('default-v2'),
      'ref diversi devono dare hash diversi');

  // La riga conserva l'hash del ref, mai il body.
  final log = const RejectLog().logRejectedCall(
      normalizedNumber: '+393330000030', templateRef: ref);
  _check(log.length == 1, 'attesa 1 riga');
  final entry = log.entries.single;
  _check(entry.templateRefHash == hash,
      'riga deve portare hash del template_ref, trovato ${entry.templateRefHash}');
  _check(entry.templateRefHash != body, 'riga non deve contenere il body');
  _check(!entry.templateRefHash.contains(body),
      'hash non deve inglobare il body');
  _check(!body.contains(entry.templateRefHash),
      'body non deve comparire come hash');

  // Anche su due righe stesso numero: hash su entrambe, mai body.
  final log2 = log.logRejectedCall(
      normalizedNumber: '+393330000030', templateRef: ref);
  _check(log2.length == 2, 'attese 2 righe');
  for (final e in log2.entries) {
    _check(e.templateRefHash == hash, 'ogni riga porta hash del template_ref');
    _check(e.templateRefHash != body, 'nessuna riga contiene il body');
  }

  stdout.writeln('TP-701 PASSED: righe con template_ref hash $hash, mai body');
}
