// TP-802: profilo con 3 campi modificabili e persistiti.
// Eseguibile con: dart test/tp_802_test.dart
import 'dart:io';
import '../src/domain/sms_template.dart';
import '../src/domain/user_profile.dart';

void _fail(String msg) {
  stderr.writeln('TP-802 FAILED: $msg');
  exit(1);
}

void _check(bool cond, String msg) {
  if (!cond) _fail(msg);
}

void main() {
  // Default con 3 campi.
  final d = UserProfile.defaults();
  _check(d.smsText == defaultSmsText, 'default SMS atteso');
  _check(d.isSmsTextValid, 'default deve essere valido');

  // Edit di tutti e 3 i campi.
  final edited = d.edit(
    displayName: 'Mario',
    smsText: 'Ti richiamo dopo.',
    blacklistSmsEnabled: false,
  );
  _check(edited.displayName == 'Mario', 'campo displayName');
  _check(edited.smsText == 'Ti richiamo dopo.', 'campo smsText');
  _check(edited.blacklistSmsEnabled == false, 'campo flag');

  // Persistenza: round-trip su mappa.
  final map = edited.toMap();
  _check(map.length == 3, 'persistiti esattamente 3 campi');
  _check(map.containsKey('displayName'), 'manca displayName');
  _check(map.containsKey('smsText'), 'manca smsText');
  _check(map.containsKey('blacklistSmsEnabled'), 'manca flag');
  final reloaded = UserProfile.fromMap(map);
  _check(reloaded.displayName == 'Mario', 'reload displayName');
  _check(reloaded.smsText == 'Ti richiamo dopo.', 'reload smsText');
  _check(reloaded.blacklistSmsEnabled == false, 'reload flag');

  // Secondo edit parziale preserva gli altri campi.
  final again = reloaded.edit(displayName: 'Luigi');
  _check(again.displayName == 'Luigi', 'secondo edit nome');
  _check(again.smsText == 'Ti richiamo dopo.', 'secondo edit preserva sms');
  final map2 = again.toMap();
  final re2 = UserProfile.fromMap(map2);
  _check(re2.displayName == 'Luigi', 'persist secondo edit');

  // Corrotto degrada senza throw.
  final corrupt = UserProfile.fromMap(const <String, String>{});
  _check(corrupt.smsText == defaultSmsText, 'corrotto degrada a default SMS');

  stdout.writeln('TP-802 PASSED: profilo 3 campi edit + persistiti');
}
