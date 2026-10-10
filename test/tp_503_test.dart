// TP-503: default SMS carattere-esatto e valido per l'invio.
// Eseguibile con: dart test/tp_503_test.dart
import 'dart:io';
import '../src/domain/sms_template.dart';

void _fail(String msg) {
  stderr.writeln('TP-503 FAILED: $msg');
  exit(1);
}

void _check(bool cond, String msg) {
  if (!cond) _fail(msg);
}

void main() {
  _check(maxSmsChars == 480, 'limite atteso 480, trovato $maxSmsChars');

  // Confronto carattere-esatto del default.
  const expected =
      'Non posso rispondere ora. Ti richiamero il prima possibile.';
  _check(defaultSmsText == expected, 'default SMS deve corrispondere carattere-esatto');
  _check(defaultSmsText.length == expected.length,
      'lunghezza carattere-esatta attesa ${expected.length}');

  // Il default deve essere non vuoto, entro il limite e valido.
  _check(defaultSmsText.isNotEmpty, 'default non deve essere vuoto');
  _check(defaultSmsText.length <= maxSmsChars, 'default entro 480 caratteri');
  _check(isSmsTextValid(defaultSmsText), 'default deve passare la validazione');
  _check(validateSmsText(defaultSmsText).valid, 'validazione default deve essere ok');

  stdout.writeln(
      'TP-503 PASSED: default carattere-esatto (${defaultSmsText.length} caratteri), valido');
}
