// TP-1202: senza READ_CONTACTS confronto rubrica disattivato con messaggio.
// Eseguibile con: dart test/tp_1202_test.dart
import 'dart:io';
import '../src/domain/phone_number.dart';
import '../src/domain/screening_decision.dart';
import '../src/domain/screening_snapshot.dart';

void _fail(String msg) {
  stderr.writeln('TP-1202 FAILED: $msg');
  exit(1);
}

void _check(bool cond, String msg) {
  if (!cond) _fail(msg);
}

void main() {
  const snapshot = ScreeningSnapshot(contacts: ['+393330000001']);

  // Con permesso: il contatto e' riconosciuto e passa con origine contacts.
  final withPerm = lookupContacts(
    snapshot: snapshot,
    normalizedNumber: '+393330000001',
    hasReadContacts: true,
  );
  _check(withPerm.matched, 'con permesso il contatto deve matchare');
  _check(!withPerm.accessMissing, 'con permesso nessuna vista accesso mancante');

  final vContact = decideForNumberWithContactsPermission(
    raw: '+393330000001',
    presentation: Presentation.allowed,
    snapshot: snapshot,
    roleHeld: true,
    hasReadContacts: true,
  );
  _check(vContact.action == ScreeningAction.pass, 'contatto con permesso deve passare');
  _check(vContact.origin == DecisionOrigin.contacts, 'origine contacts');
  _check(vContact.actuation == ScreeningActuation.ring, 'attuazione ring');

  // Senza READ_CONTACTS: confronto disattivato con messaggio.
  final without = lookupContacts(
    snapshot: snapshot,
    normalizedNumber: '+393330000001',
    hasReadContacts: false,
  );
  _check(!without.matched, 'senza permesso nessun match (confronto disattivato)');
  _check(without.accessMissing, 'senza permesso vista accesso mancante');
  _check(without.message != null && without.message!.isNotEmpty,
      'senza permesso messaggio obbligatorio');
  _check(without.message == contactsDisabledMessage, 'messaggio atteso contactsDisabledMessage');
  final viaAlias = resolveContactsMatch(
    snapshot: snapshot,
    normalizedNumber: '+393330000001',
    hasReadContacts: false,
  );
  _check(!viaAlias.matched && viaAlias.accessMissing, 'alias resolveContactsMatch coerente');

  // Decisione senza permesso: inContacts forzato a false => sconosciuto
  // disallow (reject/disconnect, senza squillo), non passa da rubrica.
  final vNoPerm = decideForNumberWithContactsPermission(
    raw: '+393330000001',
    presentation: Presentation.allowed,
    snapshot: snapshot,
    roleHeld: true,
    hasReadContacts: false,
  );
  _check(vNoPerm.action == ScreeningAction.reject,
      'senza permesso il contatto non riconosciuto deve rifiutare');
  _check(vNoPerm.origin == DecisionOrigin.unknown, 'origine unknown senza rubrica');
  _check(vNoPerm.actuation == ScreeningActuation.disconnect, 'senza squillo: disconnect');
  _check(vNoPerm.origin != DecisionOrigin.contacts, 'mai origine contacts senza permesso');

  // Formati equivalenti restano equivalenti quando il permesso c'e'.
  final vEquiv = decideForNumberWithContactsPermission(
    raw: '+39 333 000 0001',
    presentation: Presentation.allowed,
    snapshot: snapshot,
    roleHeld: true,
    hasReadContacts: true,
  );
  _check(vEquiv.origin == DecisionOrigin.contacts, 'equivalenza formati con permesso');

  // Senza permesso anche i formati equivalenti non matchano.
  final vEquivNoPerm = decideForNumberWithContactsPermission(
    raw: '+39 333 000 0001',
    presentation: Presentation.allowed,
    snapshot: snapshot,
    roleHeld: true,
    hasReadContacts: false,
  );
  _check(vEquivNoPerm.action == ScreeningAction.reject, 'equivalente senza permesso rifiuta');

  stdout.writeln('TP-1202 PASSED: senza READ_CONTACTS confronto disattivato con messaggio');
}
