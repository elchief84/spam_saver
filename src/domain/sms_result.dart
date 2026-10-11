// Modulo domain: mapping esiti piattaforma SMS -> esito domain.
// Puro Dart, zero dipendenze piattaforma.
// Politica:
// - SUCCESS mappa sent;
// - NO_SERVICE mappa failed;
// - qualsiasi altro errore piattaforma mappa failed;
// - short-code / alfanumerici / non composti: zero invii (suppressed
//   dal gate di eleggibilita', mai chiamata al sender).
// Funzioni totali: mai throw.

import 'phone_number.dart';
import 'sms_dispatch.dart';

/// Codici piattaforma normalizzati per l'invio SMS.
enum SmsPlatformDelivery {
  /// Invio accettato dalla piattaforma.
  success,

  /// Servizio non disponibile.
  noService,

  /// Errore generico piattaforma.
  genericFailure,

  /// Radio spenta.
  radioOff,

  /// PDU nulla.
  nullPdu,
}

/// Mappa un esito piattaforma normalizzato su esito domain.
/// SUCCESS -> sent, tutto il resto -> failed.
SmsSendOutcome mapSmsPlatformDelivery(SmsPlatformDelivery code) {
  switch (code) {
    case SmsPlatformDelivery.success:
      return SmsSendOutcome.sent;
    case SmsPlatformDelivery.noService:
    case SmsPlatformDelivery.genericFailure:
    case SmsPlatformDelivery.radioOff:
    case SmsPlatformDelivery.nullPdu:
      return SmsSendOutcome.failed;
  }
}

/// Mappa un nome codice piattaforma (es. "SUCCESS", "NO_SERVICE")
/// su esito domain. Confronto case-insensitive, trim.
/// "SUCCESS" (e "RESULT_OK"/"OK") -> sent; "NO_SERVICE" e ogni
/// altro valore / vuoto / sconosciuto -> failed. Totale.
SmsSendOutcome mapSmsPlatformCodeName(String? name) {
  final n = (name ?? '').trim().toUpperCase();
  if (n == 'SUCCESS' || n == 'RESULT_OK' || n == 'OK') {
    return SmsSendOutcome.sent;
  }
  return SmsSendOutcome.failed;
}

/// Alias con nome alternativo.
SmsSendOutcome mapPlatformResult(SmsPlatformDelivery code) =>
    mapSmsPlatformDelivery(code);

/// Alias con nome alternativo per nomi stringa.
SmsSendOutcome mapPlatformResultName(String? name) =>
    mapSmsPlatformCodeName(name);

/// True se l'esito piattaforma indica invio riuscito.
bool isPlatformSuccess(SmsPlatformDelivery code) =>
    mapSmsPlatformDelivery(code) == SmsSendOutcome.sent;

/// True se l'esito piattaforma indica fallimento (es. NO_SERVICE).
bool isPlatformFailure(SmsPlatformDelivery code) =>
    mapSmsPlatformDelivery(code) == SmsSendOutcome.failed;

/// True se l'invio verso [rawNumber] deve essere soppresso con zero
/// chiamate al sender (short-code, alfanumerici, non composti).
/// E' la stessa regola di [isSmsDialable] rovesciata.
bool mustSuppressSmsSend(String? rawNumber) => !isSmsDialable(rawNumber);
