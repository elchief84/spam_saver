// Modulo domain: invio SMS idempotente per event_id con gate di eleggibilita'.
// Puro Dart, zero dipendenze piattaforma.
// Politica:
// - doppio evento con stesso event_id => un solo invio, il secondo e'
//   duplicate-suppressed senza richiamare il sender;
// - eligibility Skipped (es. flag OFF su blacklist) => skipped senza
//   chiamare il sender;
// - ogni event_id visto (inviato o skippato) e' registrato per dedup.
// Immutabile: ogni dispatch restituisce un nuovo [SmsDispatcher].
// Funzioni totali: mai throw (il sender di test deve essere totale).

import 'sms_eligibility.dart';

/// Esito di un tentativo di invio.
enum SmsSendOutcome {
  /// Inviato tramite sender (una sola volta per event_id).
  sent,

  /// Inibito dal gate, sender mai chiamato.
  skipped,

  /// event_id gia' visto: nessun secondo invio, sender mai chiamato.
  duplicateSuppressed,
}

/// Evento di invio con chiave di idempotenza.
class SmsDispatchEvent {
  final String eventId;
  final SmsFacts facts;

  const SmsDispatchEvent({required this.eventId, required this.facts});
}

/// Risultato di [SmsDispatcher.dispatch] con dispatcher aggiornato.
class SmsDispatchResult {
  final SmsDispatcher dispatcher;
  final SmsSendOutcome outcome;
  final SmsSkipReason? skipReason;

  const SmsDispatchResult(this.dispatcher, this.outcome, [this.skipReason]);
}

/// Dispatcher immutabile con memoria degli event_id visti.
class SmsDispatcher {
  final Set<String> seenEventIds;
  final int senderCalls;

  const SmsDispatcher({this.seenEventIds = const {}, this.senderCalls = 0});

  /// Numero di event_id distinti gia' processati.
  int get seenCount => seenEventIds.length;

  /// True se [eventId] e' gia' stato processato.
  bool hasSeen(String eventId) => seenEventIds.contains(eventId);

  /// Tenta l'invio di [event]:
  /// - event_id gia' visto => duplicateSuppressed, sender mai chiamato;
  /// - gate Skipped => skipped con motivo, sender mai chiamato;
  /// - gate Eligible => chiama [sender] esattamente una volta, esito sent.
  /// Registra l'event_id in tutti i casi non-duplicati.
  SmsDispatchResult dispatch(
    SmsDispatchEvent event,
    void Function() sender,
  ) {
    if (seenEventIds.contains(event.eventId)) {
      return SmsDispatchResult(
        this,
        SmsSendOutcome.duplicateSuppressed,
      );
    }
    final seen = <String>{...seenEventIds, event.eventId};
    final eligibility = checkSmsEligibility(event.facts);
    if (eligibility is Skipped) {
      return SmsDispatchResult(
        SmsDispatcher(seenEventIds: seen, senderCalls: senderCalls),
        SmsSendOutcome.skipped,
        eligibility.reason,
      );
    }
    sender();
    return SmsDispatchResult(
      SmsDispatcher(seenEventIds: seen, senderCalls: senderCalls + 1),
      SmsSendOutcome.sent,
    );
  }
}
