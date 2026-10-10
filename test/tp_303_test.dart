// TP-303: contatti passano senza log ne' SMS.
// Eseguibile con: dart test/tp_303_test.dart
import 'dart:io';
import '../src/domain/phone_number.dart';
import '../src/domain/screening_decision.dart';

void _fail(String msg) {
  stderr.writeln('TP-303 FAILED: $msg');
  exit(1);
}

void _check(bool cond, String msg) {
  if (!cond) _fail(msg);
}

void main() {
  final contact = classifyCallerId(const RawCallerId(
      raw: '+39 333 000 0001', presentation: Presentation.allowed));
  _check(contact is Visible, 'contatto deve essere Visible');
  final v = decideScreening(ScreeningFacts(
    visibility: contact,
    inContacts: true,
    inWhitelist: false,
    inBlacklist: false,
    roleHeld: true,
  ));
  _check(v.action == ScreeningAction.pass, 'contatto deve passare');
  _check(v.origin == DecisionOrigin.contacts, 'origine deve essere contacts');
  _check(v.actuation == ScreeningActuation.ring, 'attuazione deve essere ring');

  // Il passaggio implica nessuna registrazione e nessun SMS a livello domain.
  stdout.writeln('TP-303 PASSED: contatto passa senza log ne SMS');
}
