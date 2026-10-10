// TP-302: rifiuto sse visibile E non in rubrica E non in whitelist (con ruolo).
// Eseguibile con: dart test/tp_302_test.dart
import 'dart:io';
import '../src/domain/phone_number.dart';
import '../src/domain/screening_decision.dart';

void _fail(String msg) {
  stderr.writeln('TP-302 FAILED: $msg');
  exit(1);
}

void _check(bool cond, String msg) {
  if (!cond) _fail(msg);
}

ScreeningVerdict _decide({
  required PhoneNumberResult visibility,
  bool inContacts = false,
  bool inWhitelist = false,
  bool inBlacklist = false,
  required bool roleHeld,
}) {
  return decideScreening(ScreeningFacts(
    visibility: visibility,
    inContacts: inContacts,
    inWhitelist: inWhitelist,
    inBlacklist: inBlacklist,
    roleHeld: roleHeld,
  ));
}

void main() {
  final visibleUnknown = classifyCallerId(
      const RawCallerId(raw: '+393330000030', presentation: Presentation.allowed));
  _check(visibleUnknown is Visible, 'fixture sconosciuto deve essere Visible');
  final hidden = classifyCallerId(const RawCallerId(
      raw: '+393330000030', presentation: Presentation.restricted));
  final empty = classifyCallerId(
      const RawCallerId(raw: '', presentation: Presentation.allowed));

  var rejects = 0;
  void expect(ScreeningVerdict v, bool wantReject, String label) {
    if (wantReject) {
      rejects++;
      _check(v.action == ScreeningAction.reject, '$label deve essere REJECT');
    } else {
      _check(v.action == ScreeningAction.pass, '$label deve essere PASS');
    }
  }

  // 1-2: visibile sconosciuto x ruolo.
  expect(_decide(visibility: visibleUnknown, roleHeld: true), true, 'sconosciuto+ruolo');
  expect(_decide(visibility: visibleUnknown, roleHeld: false), false, 'sconosciuto senza ruolo');
  // 3-4: in rubrica x ruolo.
  expect(_decide(visibility: visibleUnknown, inContacts: true, roleHeld: true), false, 'rubrica+ruolo');
  expect(_decide(visibility: visibleUnknown, inContacts: true, roleHeld: false), false, 'rubrica senza ruolo');
  // 5-6: in whitelist x ruolo.
  expect(_decide(visibility: visibleUnknown, inWhitelist: true, roleHeld: true), false, 'whitelist+ruolo');
  expect(_decide(visibility: visibleUnknown, inWhitelist: true, roleHeld: false), false, 'whitelist senza ruolo');
  // 7-8: hidden x ruolo.
  expect(_decide(visibility: hidden, roleHeld: true), false, 'hidden+ruolo');
  expect(_decide(visibility: hidden, roleHeld: false), false, 'hidden senza ruolo');
  // 9-10: vuoto x ruolo.
  expect(_decide(visibility: empty, roleHeld: true), false, 'vuoto+ruolo');
  expect(_decide(visibility: empty, roleHeld: false), false, 'vuoto senza ruolo');

  _check(rejects == 1, 'un solo rifiuto atteso su 10 combo, trovati $rejects');
  stdout.writeln('TP-302 PASSED: 10/10 combo conformi, nessun rifiuto senza ruolo');
}
