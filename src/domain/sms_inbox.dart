// Modulo domain: lettura SMS scoped con watermark, solo foreground,
// con dedup su provider_msg_id e vista di accesso mancante.
// Puro Dart, zero dipendenze piattaforma.
// Politica:
// - senza permesso di lettura SMS: zero letture, vista con
//   accessMissing=true, watermark invariato;
// - solo foreground: in background zero letture, watermark invariato;
// - query scoped su watermark: solo righe con rowId > watermark,
//   ordinate per rowId, al massimo [inboxCap] (200) righe;
// - dedup su provider_msg_id: stesso id provider emesso una sola volta,
//   sia dentro il batch sia contro gli id gia' visti;
// - funzioni totali: mai throw.

/// Cap massimo di righe per singola lettura.
const int inboxCap = 200;

/// Alias del cap per compatibilita'.
const int smsInboxCap = inboxCap;

/// Alias del cap per compatibilita'.
const int maxInboxRows = inboxCap;

/// Riga provider minimale: id riga crescente + id messaggio provider.
class ProviderSms {
  final int rowId;
  final String providerMsgId;
  final String address;

  const ProviderSms({
    required this.rowId,
    required this.providerMsgId,
    required this.address,
  });
}

/// Stato della lettura: watermark + id provider gia' emessi.
class SmsInboxState {
  final int watermark;
  final Set<String> seenProviderIds;

  const SmsInboxState({this.watermark = 0, this.seenProviderIds = const {}});

  /// Numero di id provider distinti gia' emessi.
  int get seenCount => seenProviderIds.length;
}

/// Risultato di una lettura con stato aggiornato.
class SmsInboxRead {
  final SmsInboxState state;
  final List<ProviderSms> messages;

  /// True quando manca il permesso di lettura (vista accesso mancante).
  final bool accessMissing;

  const SmsInboxRead({
    required this.state,
    required this.messages,
    required this.accessMissing,
  });

  /// Watermark dopo la lettura.
  int get nextWatermark => state.watermark;
}

/// Legge la casella in modo scoped:
/// - [hasSmsRead]=false => zero letture, accessMissing=true;
/// - [isForeground]=false => zero letture, watermark invariato;
/// - altrimenti: righe con rowId > watermark, dedup su providerMsgId,
///   al massimo [cap] (default 200), watermark avanzato al max rowId
///   consumato. Totale.
SmsInboxRead readSmsInbox({
  required SmsInboxState state,
  required bool isForeground,
  required bool hasSmsRead,
  required List<ProviderSms> rows,
  int cap = inboxCap,
}) {
  if (!hasSmsRead) {
    return SmsInboxRead(
      state: state,
      messages: const [],
      accessMissing: true,
    );
  }
  if (!isForeground) {
    return SmsInboxRead(
      state: state,
      messages: const [],
      accessMissing: false,
    );
  }
  final limit = cap <= 0 ? inboxCap : cap;
  final scoped = rows.where((r) => r.rowId > state.watermark).toList()
    ..sort((a, b) => a.rowId.compareTo(b.rowId));
  final out = <ProviderSms>[];
  final seen = Set<String>.of(state.seenProviderIds);
  var watermark = state.watermark;
  for (final r in scoped) {
    if (out.length >= limit) break;
    if (r.providerMsgId.isEmpty) continue;
    if (seen.contains(r.providerMsgId)) {
      if (r.rowId > watermark) watermark = r.rowId;
      continue;
    }
    seen.add(r.providerMsgId);
    out.add(r);
    if (r.rowId > watermark) watermark = r.rowId;
  }
  // Se nulla di nuovo ma c'erano righe scoped e tutte duplicate,
  // il watermark avanza comunque per non rileggerle.
  return SmsInboxRead(
    state: SmsInboxState(watermark: watermark, seenProviderIds: seen),
    messages: out,
    accessMissing: false,
  );
}

/// Alias con nome alternativo.
SmsInboxRead querySmsInbox({
  required SmsInboxState state,
  required bool isForeground,
  required bool hasSmsRead,
  required List<ProviderSms> rows,
  int cap = inboxCap,
}) =>
    readSmsInbox(
      state: state,
      isForeground: isForeground,
      hasSmsRead: hasSmsRead,
      rows: rows,
      cap: cap,
    );

/// Scorciatoia: true se la vista indica accesso mancante.
bool isAccessMissing(SmsInboxRead read) => read.accessMissing;
