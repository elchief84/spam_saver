// Modulo domain: registro puro delle chiamate rifiutate.
// Puro Dart, zero dipendenze piattaforma.
// Ogni chiamata rifiutata aggiunge una riga: due chiamate allo stesso
// numero producono due righe (nessuna deduplica). La riga conserva solo
// l'hash del template_ref SMS, mai il corpo del messaggio.

/// Hash stabile (FNV-1a 32 bit, esadecimale) di una stringa.
/// Puro e deterministico: stesso input, stesso hash.
String hashTemplateRef(String templateRef) {
  var hash = 0x811c9dc5;
  for (final unit in templateRef.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}

/// Riga del registro: numero normalizzato, hash del template, istante.
/// Non esiste alcun campo corpo-messaggio, per costruzione.
class RejectLogEntry {
  final String numberKey;
  final String templateRefHash;
  final DateTime rejectedAt;

  const RejectLogEntry({
    required this.numberKey,
    required this.templateRefHash,
    required this.rejectedAt,
  });
}

/// Registro immutabile: [logRejectedCall] restituisce un nuovo registro
/// con una riga in piu'. Funzione totale: mai throw.
class RejectLog {
  final List<RejectLogEntry> entries;

  const RejectLog([this.entries = const []]);

  /// Numero di righe registrate.
  int get length => entries.length;

  /// Registra una chiamata rifiutata. Due chiamate allo stesso numero
  /// producono due righe distinte.
  RejectLog logRejectedCall({
    required String normalizedNumber,
    required String templateRef,
    DateTime? at,
  }) {
    return RejectLog([
      ...entries,
      RejectLogEntry(
        numberKey: normalizedNumber,
        templateRefHash: hashTemplateRef(templateRef),
        rejectedAt: at ?? DateTime.now(),
      ),
    ]);
  }
}
