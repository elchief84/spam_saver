// Modulo domain: registro rifiutate con coda pendenti e retry.
// Puro Dart, zero dipendenze piattaforma.
// Politica: solo i verdetti REJECT producono righe; i PASS (anonimi,
// contatti, whitelist, no-role) non sono mai registrati ne' accodati.
// Se lo store non e' scrivibile (STORE_UNWRITABLE) la scrittura viene
// accodata nei pendenti, mai scartata in silenzio; il prossimo open con
// store scrivibile riversa i pendenti in ordine. Funzioni totali.

import 'reject_log.dart';
import 'screening_decision.dart';

/// Esito di un tentativo di registrazione.
enum StoreWriteOutcome {
  /// Riga aggiunta al registro.
  stored,

  /// Store non scrivibile: accodato nei pendenti, mai scartato.
  queuedUnwritable,

  /// Verdetto PASS: nessuna riga per politica, nulla accodato.
  ignoredPass,
}

/// Scrittura pendente in attesa di retry al prossimo open.
class PendingReject {
  final String normalizedNumber;
  final String templateRef;
  final DateTime rejectedAt;

  const PendingReject({
    required this.normalizedNumber,
    required this.templateRef,
    required this.rejectedAt,
  });
}

/// Risultato di [RejectStore.logDecision] con lo store aggiornato.
class RejectWriteResult {
  final RejectStore store;
  final StoreWriteOutcome outcome;

  const RejectWriteResult(this.store, this.outcome);
}

/// Store immutabile: ogni operazione restituisce un nuovo [RejectStore].
class RejectStore {
  final RejectLog committed;
  final List<PendingReject> pending;
  final bool writable;

  const RejectStore({
    this.committed = const RejectLog(),
    this.pending = const [],
    this.writable = true,
  });

  /// Righe consolidate nel registro.
  int get committedCount => committed.length;

  /// Scritture in attesa di retry.
  int get pendingCount => pending.length;

  /// Registra secondo politica: PASS mai loggato; REJECT consolidato
  /// se scrivibile, altrimenti accodato (mai drop silenzioso).
  RejectWriteResult logDecision({
    required ScreeningVerdict verdict,
    required String normalizedNumber,
    required String templateRef,
    DateTime? at,
  }) {
    if (!verdict.shouldReject) {
      return RejectWriteResult(this, StoreWriteOutcome.ignoredPass);
    }
    final stamp = at ?? DateTime.now();
    if (!writable) {
      return RejectWriteResult(
        RejectStore(
          committed: committed,
          pending: [
            ...pending,
            PendingReject(
              normalizedNumber: normalizedNumber,
              templateRef: templateRef,
              rejectedAt: stamp,
            ),
          ],
          writable: false,
        ),
        StoreWriteOutcome.queuedUnwritable,
      );
    }
    return RejectWriteResult(
      RejectStore(
        committed: committed.logRejectedCall(
          normalizedNumber: normalizedNumber,
          templateRef: templateRef,
          at: stamp,
        ),
        pending: pending,
        writable: true,
      ),
      StoreWriteOutcome.stored,
    );
  }

  /// Apertura dello store: aggiorna la scrivibilita' e, se ora
  /// scrivibile, riversa i pendenti in ordine nel registro.
  RejectStore open({required bool writable}) {
    if (!writable) {
      return RejectStore(
        committed: committed,
        pending: pending,
        writable: false,
      );
    }
    var log = committed;
    for (final p in pending) {
      log = log.logRejectedCall(
        normalizedNumber: p.normalizedNumber,
        templateRef: p.templateRef,
        at: p.rejectedAt,
      );
    }
    return RejectStore(
      committed: log,
      pending: const [],
      writable: true,
    );
  }
}
