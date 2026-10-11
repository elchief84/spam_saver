// Modulo domain: screening su snapshot locale, zero rete, offline.
// Puro Dart, zero dipendenze piattaforma.
// La decisione usa solo lo snapshot congelato (contatti, whitelist,
// blacklist) e fatti locali: nessun I/O, nessuna rete, funziona anche
// offline con lo stesso esito. Funzione sincrona e totale: mai throw.

import 'phone_number.dart';
import 'screening_decision.dart';

/// Budget massimo per una singola decisione: 500ms.
const int maxDecisionMillis = 500;

/// Microsecondi equivalenti del budget (500ms).
const int maxDecisionMicros = 500 * 1000;

/// Snapshot congelato delle liste al momento dell'apertura.
// Offre lookup per equivalenza numerica (prefisso paese / trunk).
class ScreeningSnapshot {
  final List<String> contacts;
  final List<String> whitelist;
  final List<String> blacklist;

  const ScreeningSnapshot({
    this.contacts = const [],
    this.whitelist = const [],
    this.blacklist = const [],
  });

  bool _contains(List<String> side, String normalized) {
    for (final entry in side) {
      if (areEquivalentNumbers(entry, normalized)) return true;
    }
    return false;
  }

  bool inContacts(String normalizedNumber) =>
      _contains(contacts, normalizedNumber);

  bool inWhitelist(String normalizedNumber) =>
      _contains(whitelist, normalizedNumber);

  bool inBlacklist(String normalizedNumber) =>
      _contains(blacklist, normalizedNumber);
}

/// Decisione sincrona dal solo snapshot. [offline] e' accettato e
/// ignorato: l'esito non dipende dalla connettivita' per costruzione
/// (nessun ramo rete). Funzione totale: mai throw.
ScreeningVerdict decideForNumber({
  required String? raw,
  required Presentation presentation,
  required ScreeningSnapshot snapshot,
  required bool roleHeld,
  bool offline = false,
}) {
  final visibility =
      classifyCallerId(RawCallerId(raw: raw, presentation: presentation));
  final String? normalized =
      visibility is Visible ? visibility.number.normalized : null;
  return decideScreening(ScreeningFacts(
    visibility: visibility,
    inContacts:
        normalized != null && snapshot.inContacts(normalized),
    inWhitelist:
        normalized != null && snapshot.inWhitelist(normalized),
    inBlacklist:
        normalized != null && snapshot.inBlacklist(normalized),
    roleHeld: roleHeld,
  ));
}

/// True se [elapsed] rispetta il budget di 500ms.
bool meetsDecisionBudget(Duration elapsed) =>
    elapsed.inMicroseconds <= maxDecisionMicros;

/// Messaggio mostrato quando il confronto rubrica e' disattivato per
/// mancanza del permesso READ_CONTACTS.
const String contactsDisabledMessage =
    'Confronto rubrica disattivato: concedi READ_CONTACTS per confrontare i contatti.';

/// Alias del messaggio per compatibilita'.
const String readContactsMissingMessage = contactsDisabledMessage;

/// Alias del messaggio per compatibilita'.
const String contactsPermissionMessage = contactsDisabledMessage;

/// Esito del lookup rubrica con gate di permesso.
class ContactsLookup {
  final bool matched;
  final bool accessMissing;
  final String? message;

  const ContactsLookup({
    required this.matched,
    required this.accessMissing,
    this.message,
  });
}

/// Lookup rubrica con gate READ_CONTACTS: se [hasReadContacts] e' false
/// il confronto e' disattivato (matched=false) con vista accesso mancante
/// e messaggio; altrimenti cerca nello snapshot per equivalenza numerica.
/// Totale: mai throw.
ContactsLookup lookupContacts({
  required ScreeningSnapshot snapshot,
  required String normalizedNumber,
  required bool hasReadContacts,
}) {
  if (!hasReadContacts) {
    return const ContactsLookup(
      matched: false,
      accessMissing: true,
      message: contactsDisabledMessage,
    );
  }
  if (normalizedNumber.isEmpty) {
    return const ContactsLookup(matched: false, accessMissing: false);
  }
  final matched = snapshot.inContacts(normalizedNumber);
  return ContactsLookup(matched: matched, accessMissing: false);
}

/// Alias del lookup con gate di permesso.
ContactsLookup resolveContactsMatch({
  required ScreeningSnapshot snapshot,
  required String normalizedNumber,
  required bool hasReadContacts,
}) =>
    lookupContacts(
      snapshot: snapshot,
      normalizedNumber: normalizedNumber,
      hasReadContacts: hasReadContacts,
    );

/// Decisione con gate READ_CONTACTS: senza permesso il confronto rubrica
/// e' disattivato (inContacts=false) e il messaggio di [ContactsLookup]
/// spiega il perche'; l'esito resta quello di [decideForNumber] con
/// inContacts forzato a false. Accetta e ignora [offline] come
/// [decideForNumber]. Totale: mai throw.
ScreeningVerdict decideForNumberWithContactsPermission({
  required String? raw,
  required Presentation presentation,
  required ScreeningSnapshot snapshot,
  required bool roleHeld,
  required bool hasReadContacts,
  bool offline = false,
}) {
  final visibility =
      classifyCallerId(RawCallerId(raw: raw, presentation: presentation));
  final String? normalized =
      visibility is Visible ? visibility.number.normalized : null;
  final bool inContacts = normalized != null &&
      lookupContacts(
        snapshot: snapshot,
        normalizedNumber: normalized,
        hasReadContacts: hasReadContacts,
      ).matched;
  return decideScreening(ScreeningFacts(
    visibility: visibility,
    inContacts: inContacts,
    inWhitelist:
        normalized != null && snapshot.inWhitelist(normalized),
    inBlacklist:
        normalized != null && snapshot.inBlacklist(normalized),
    roleHeld: roleHeld,
  ));
}

/// Alias della decisione con gate READ_CONTACTS.
ScreeningVerdict decideWithContactsPermission({
  required String? raw,
  required Presentation presentation,
  required ScreeningSnapshot snapshot,
  required bool roleHeld,
  required bool hasReadContacts,
  bool offline = false,
}) =>
    decideForNumberWithContactsPermission(
      raw: raw,
      presentation: presentation,
      snapshot: snapshot,
      roleHeld: roleHeld,
      hasReadContacts: hasReadContacts,
      offline: offline,
    );
