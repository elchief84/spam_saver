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
