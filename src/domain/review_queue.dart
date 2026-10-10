// Modulo domain: coda di revisione per soli rifiutati non classificati.
// Puro Dart, zero dipendenze piattaforma.
// Politica: solo i verdetti REJECT con origine unknown (numero rifiutato
// non classificato in nessuna lista) entrano in coda pending, con link
// alla riga del registro rifiutate. Tutti gli altri casi (PASS di
// qualsiasi origine, REJECT blacklist) non accodano nulla.
// Immutabile: ogni operazione restituisce una nuova [ReviewQueue].
// Funzioni totali: mai throw.

import 'screening_decision.dart';

/// Voce in attesa di classificazione con link al registro.
class PendingReview {
  final String numberKey;
  final String rejectLink;
  final DateTime queuedAt;

  const PendingReview({
    required this.numberKey,
    required this.rejectLink,
    required this.queuedAt,
  });
}

/// Coda pendenti di revisione. Immutabile.
class ReviewQueue {
  final List<PendingReview> pending;

  const ReviewQueue([this.pending = const []]);

  /// Voci in attesa.
  int get length => pending.length;

  /// True se la coda e' vuota.
  bool get isEmpty => pending.isEmpty;

  /// Accoda solo se [verdict] e' REJECT con origine unknown e il numero
  /// non e' vuoto; conserva [rejectLink] per ritrovare la riga.
  /// In tutti gli altri casi restituisce la stessa coda invariata.
  ReviewQueue queueIfUnclassified({
    required ScreeningVerdict verdict,
    required String normalizedNumber,
    required String rejectLink,
    DateTime? at,
  }) {
    if (!verdict.shouldReject) return this;
    if (verdict.origin != DecisionOrigin.unknown) return this;
    if (normalizedNumber.isEmpty) return this;
    if (rejectLink.isEmpty) return this;
    return ReviewQueue([
      ...pending,
      PendingReview(
        numberKey: normalizedNumber,
        rejectLink: rejectLink,
        queuedAt: at ?? DateTime.now(),
      ),
    ]);
  }
}
