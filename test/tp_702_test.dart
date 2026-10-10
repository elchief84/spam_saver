// TP-702: validazione rifiuta vuoto e oltre-480 (480 ammessi).
// Eseguibile con: dart test/tp_702_test.dart
import 'dart:io';
import '../src/domain/sms_template.dart';

void _fail(String msg) {
  stderr.writeln('TP-702 FAILED: $msg');
  exit(1);
}

void _check(bool cond, String msg) {
  if (!cond) _fail(msg);
}

String _repeat(String c, int n) => List.filled(n, c).join();

void main() {
  // Vuoto rifiutato.
  _check(!isSmsTextValid(''), 'testo vuoto deve essere rifiutato');
  final emptyRes = validateSmsText('');
  _check(!emptyRes.valid && emptyRes.reason == SmsTextInvalidReason.empty,
      'vuoto deve dare motivo empty');

  // Oltre-480 rifiutato.
  final over = _repeat('a', 481);
  _check(over.length == 481, 'fixture oltre-limite deve essere 481 caratteri');
  _check(!isSmsTextValid(over), '481 caratteri devono essere rifiutati');
  final overRes = validateSmsText(over);
  _check(!overRes.valid && overRes.reason == SmsTextInvalidReason.tooLong,
      '481 deve dare motivo tooLong');

  // Confine: 480 ammessi.
  final edge = _repeat('a', 480);
  _check(edge.length == 480, 'fixture limite deve essere 480 caratteri');
  _check(isSmsTextValid(edge), '480 caratteri devono essere ammessi');
  _check(validateSmsText(edge).valid, 'validazione 480 deve essere ok');

  // Testo normale ammesso.
  _check(isSmsTextValid('ciao'), 'testo breve deve essere ammesso');
  _check(isSmsTextValid(defaultSmsText), 'default deve essere ammesso');

  stdout.writeln('TP-702 PASSED: vuoto e oltre-480 rifiutati, 480 ammessi');
}
