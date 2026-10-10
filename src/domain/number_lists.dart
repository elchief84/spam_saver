// Modulo domain: gestione pura di whitelist e blacklist.
// Puro Dart, zero dipendenze piattaforma.
// Invariante: un numero non appartiene mai a entrambe le liste.
// Lo spostamento (move) conserva il date_added originale.

import 'phone_number.dart';

/// Liste gestite.
enum ManagedList { whitelist, blacklist }

/// Ingresso in lista con data di aggiunta.
class ManagedEntry {
  final String numberKey;
  final DateTime dateAdded;

  const ManagedEntry({required this.numberKey, required this.dateAdded});
}

/// Coppia di liste con appartenenza esclusiva. Immutabile: ogni
/// operazione restituisce un nuovo [NumberLists]. Funzioni totali,
/// mai throw.
class NumberLists {
  final Map<String, ManagedEntry> whitelist;
  final Map<String, ManagedEntry> blacklist;

  const NumberLists({
    this.whitelist = const {},
    this.blacklist = const {},
  });

  static String _key(String rawNumber) => canonicalNumberKey(rawNumber);

  Map<String, ManagedEntry> _side(ManagedList list) =>
      list == ManagedList.whitelist ? whitelist : blacklist;

  /// Ingresso in una lista, o null se assente.
  ManagedEntry? entryIn(ManagedList list, String rawNumber) =>
      _side(list)[_key(rawNumber)];

  /// True se il numero e' in whitelist.
  bool isWhitelisted(String rawNumber) =>
      whitelist.containsKey(_key(rawNumber));

  /// True se il numero e' in blacklist.
  bool isBlacklisted(String rawNumber) =>
      blacklist.containsKey(_key(rawNumber));

  /// True se il numero e' in almeno una lista.
  bool contains(String rawNumber) =>
      isWhitelisted(rawNumber) || isBlacklisted(rawNumber);

  /// Aggiunge a [list]. Se il numero e' nell'altra lista viene spostato
  /// preservando il date_added originale: mai doppia appartenenza.
  /// Se e' gia' in [list], la data resta invariata.
  NumberLists add(ManagedList list, String rawNumber, {DateTime? at}) {
    final key = _key(rawNumber);
    final target = Map<String, ManagedEntry>.of(_side(list));
    final otherList =
        list == ManagedList.whitelist ? ManagedList.blacklist : ManagedList.whitelist;
    final other = Map<String, ManagedEntry>.of(_side(otherList));
    final existing = target[key] ?? other[key];
    final entry = existing ??
        ManagedEntry(numberKey: key, dateAdded: at ?? DateTime.now());
    target[key] = entry;
    other.remove(key);
    return _rebuild(list, target, other);
  }

  /// Sposta il numero in [to] preservando il date_added originale.
  /// Se assente da entrambe, lo inserisce con [at] (o ora).
  /// Se gia' in [to], la data resta invariata. Mai doppia appartenenza.
  NumberLists moveTo(String rawNumber,
      {required ManagedList to, DateTime? at}) {
    return add(to, rawNumber, at: at);
  }

  /// Rimuove il numero da entrambe le liste.
  NumberLists remove(String rawNumber) {
    final key = _key(rawNumber);
    final white = Map<String, ManagedEntry>.of(whitelist)..remove(key);
    final black = Map<String, ManagedEntry>.of(blacklist)..remove(key);
    return NumberLists(whitelist: white, blacklist: black);
  }

  NumberLists _rebuild(ManagedList updated, Map<String, ManagedEntry> target,
      Map<String, ManagedEntry> other) {
    if (updated == ManagedList.whitelist) {
      return NumberLists(whitelist: target, blacklist: other);
    }
    return NumberLists(whitelist: other, blacklist: target);
  }
}
