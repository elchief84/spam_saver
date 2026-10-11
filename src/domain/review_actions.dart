// Modulo domain: azioni di revisione con 2 CTA esatte.
// Puro Dart, zero dipendenze piattaforma.
// Le 2 CTA sono sempre visibili senza menu, portano content-description
// distinte e ogni resolve e' annullabile tramite [ReviewHistory.undo].
// Funzioni totali: mai throw.

import 'review_queue.dart';

/// Singola CTA di revisione.
class ReviewCta {
  final String id;
  final String label;
  final String contentDescription;
  final bool visibleWithoutMenu;

  const ReviewCta({
    required this.id,
    required this.label,
    required this.contentDescription,
    this.visibleWithoutMenu = true,
  });
}

/// Prima CTA esatta.
const ReviewCta reviewCtaAllow = ReviewCta(
  id: 'allow',
  label: 'Metti in whitelist',
  contentDescription: 'Aggiungi il numero in whitelist',
  visibleWithoutMenu: true,
);

/// Seconda CTA esatta.
const ReviewCta reviewCtaBlock = ReviewCta(
  id: 'block',
  label: 'Metti in blacklist',
  contentDescription: 'Aggiungi il numero in blacklist',
  visibleWithoutMenu: true,
);

/// Le 2 CTA esatte di revisione.
const List<ReviewCta> reviewCtas = [reviewCtaAllow, reviewCtaBlock];

/// True se entrambe le CTA sono visibili senza menu.
bool reviewCtasVisibleWithoutMenu() =>
    reviewCtas.length == 2 &&
    reviewCtas.every((c) => c.visibleWithoutMenu);

/// True se le label sono esattamente quelle attese.
bool reviewCtasAreExact() =>
    reviewCtas.length == 2 &&
    reviewCtas[0].label == 'Metti in whitelist' &&
    reviewCtas[1].label == 'Metti in blacklist';

/// True se ogni CTA ha una content-description non vuota e distinta.
bool reviewCtasHaveDescriptions() {
  if (reviewCtas.length != 2) return false;
  final a = reviewCtas[0].contentDescription;
  final b = reviewCtas[1].contentDescription;
  return a.isNotEmpty && b.isNotEmpty && a != b;
}

/// Cronologia annullabile della coda di revisione. Immutabile.
class ReviewHistory {
  final ReviewQueue current;
  final List<ReviewQueue> past;

  const ReviewHistory(this.current, [this.past = const []]);

  factory ReviewHistory.start([ReviewQueue queue = const ReviewQueue()]) =>
      ReviewHistory(queue, const []);

  /// True se esiste almeno un passo annullabile.
  bool get canUndo => past.isNotEmpty;

  /// Avanza a [next] conservando lo stato per l'undo.
  ReviewHistory push(ReviewQueue next) =>
      ReviewHistory(next, [...past, current]);

  /// Annulla l'ultimo passo; senza passato restituisce se stessa.
  ReviewHistory undo() {
    if (past.isEmpty) return this;
    return ReviewHistory(past.last, past.sublist(0, past.length - 1));
  }
}
