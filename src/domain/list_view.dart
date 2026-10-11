// Modulo domain: vista delle 3 liste con filtro e ordinamento.
// Puro Dart, zero dipendenze piattaforma.
// Le 3 liste sono whitelist, blacklist e contatti. Il filtro e' per
// sottostringa (case-insensitive) sulla chiave e l'ordinamento e'
// discendente per data di aggiunta. Funzioni totali: mai throw.

import 'number_lists.dart';

/// Le 3 liste gestite dalla vista.
enum ManagedSection { whitelist, blacklist, contacts }

/// Tutte e 3 le sezioni attese.
const List<ManagedSection> allSections = [
  ManagedSection.whitelist,
  ManagedSection.blacklist,
  ManagedSection.contacts,
];

/// Voce uniforme per whitelist/blacklist/contatti.
class ListEntryView {
  final String key;
  final DateTime dateAdded;

  const ListEntryView({required this.key, required this.dateAdded});
}

/// Estrae le voci di [section] da liste + contatti.
List<ListEntryView> sectionEntries(
  NumberLists lists,
  List<String> contacts,
  ManagedSection section,
) {
  switch (section) {
    case ManagedSection.whitelist:
      return lists.whitelist.values
          .map((e) => ListEntryView(key: e.numberKey, dateAdded: e.dateAdded))
          .toList();
    case ManagedSection.blacklist:
      return lists.blacklist.values
          .map((e) => ListEntryView(key: e.numberKey, dateAdded: e.dateAdded))
          .toList();
    case ManagedSection.contacts:
      return contacts
          .map((c) => ListEntryView(key: c, dateAdded: DateTime.utc(2026, 1, 1)))
          .toList();
  }
}

/// Filtro per sottostringa case-insensitive sulla chiave.
/// Query vuota: restituisce tutte le voci. Totale.
List<ListEntryView> filterBySubstring(
  Iterable<ListEntryView> entries,
  String query,
) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return entries.toList();
  return entries.where((e) => e.key.toLowerCase().contains(q)).toList();
}

/// Ordinamento discendente per data di aggiunta. Totale, non muta l'input.
List<ListEntryView> sortByDateDesc(Iterable<ListEntryView> entries) {
  final out = entries.toList();
  out.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
  return out;
}

/// Scorciatoia: voci di sezione filtrate e ordinate disc.
List<ListEntryView> sectionFilteredSorted(
  NumberLists lists,
  List<String> contacts,
  ManagedSection section,
  String query,
) {
  return sortByDateDesc(
      filterBySubstring(sectionEntries(lists, contacts, section), query));
}
