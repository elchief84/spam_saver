// Modulo domain: puro Dart, zero dipendenze piattaforma.
// Rappresenta i task in coda per Pierino (DEV).

/// Stati possibili di un task.
enum TaskStatus {
  ready,
  blocked,
  inProgress,
  done,
}

/// Task minimo con acceptance criteria e stato di blocco.
class DevTask {
  final String id;
  final TaskStatus status;
  final bool blocked;
  final List<String> acceptanceCriteria;

  const DevTask({
    required this.id,
    required this.status,
    this.blocked = false,
    this.acceptanceCriteria = const [],
  });

  /// Prendibile da Pierino solo se `ready` e non `blocked`.
  bool get isTakable => status == TaskStatus.ready && !blocked;

  /// Bloccante reale: ferma il task.
  bool get isStopped => blocked;
}
