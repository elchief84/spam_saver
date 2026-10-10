// Gate 3 (lato DEV): regole per aprire PR su `development`.
// Puro Dart: nessuna dipendenza piattaforma.

import 'task.dart';

/// Stato CI minimo per il gate.
enum CiStatus { green, red, unknown }

/// Decisione di gate per l'apertura della PR.
class GateDecision {
  final bool allowed;
  final String reason;

  const GateDecision(this.allowed, this.reason);
}

/// La PR si apre solo quando la CI e' verde e ci sono test
/// per il comportamento aggiunto. Pierino non mergia mai qui:
/// il merge resta al Gate 3 con approvazioni TA.
GateDecision canOpenPr({
  required DevTask task,
  required CiStatus ci,
  required bool hasTests,
}) {
  if (!task.isTakable && task.status != TaskStatus.inProgress) {
    return const GateDecision(false, 'task non ready o blocked');
  }
  if (task.blocked) {
    return const GateDecision(false, 'task blocked');
  }
  if (ci != CiStatus.green) {
    return const GateDecision(false, 'CI non verde');
  }
  if (!hasTests) {
    return const GateDecision(false, 'mancano test di comportamento');
  }
  return const GateDecision(true, 'ok: CI verde + test presenti');
}

/// Bug bloccante ferma il task, quello non bloccante no.
bool shouldStopForBug({required bool blocking}) => blocking;
