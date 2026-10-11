// TP-801: 3 liste con filtro per sottostringa e sort discendente.
// Eseguibile con: dart test/tp_801_test.dart
import 'dart:io';
import '../src/domain/list_view.dart';
import '../src/domain/number_lists.dart';

void _fail(String msg) {
  stderr.writeln('TP-801 FAILED: $msg');
  exit(1);
}

void _check(bool cond, String msg) {
  if (!cond) _fail(msg);
}

void main() {
  // 3 liste presenti.
  _check(allSections.length == 3, 'attese 3 liste');
  _check(allSections.contains(ManagedSection.whitelist), 'manca whitelist');
  _check(allSections.contains(ManagedSection.blacklist), 'manca blacklist');
  _check(allSections.contains(ManagedSection.contacts), 'manca contacts');

  var lists = const NumberLists()
      .add(ManagedList.whitelist, '+393330000001',
          at: DateTime.utc(2026, 1, 1))
      .add(ManagedList.whitelist, '+393330000002',
          at: DateTime.utc(2026, 1, 2))
      .add(ManagedList.blacklist, '+393330000030',
          at: DateTime.utc(2026, 1, 3));
  final contacts = <String>['+393330000001', '+393331111111'];

  // Filtro sottostringa su whitelist.
  final white =
      sectionEntries(lists, contacts, ManagedSection.whitelist);
  _check(white.length == 2, 'whitelist attese 2 voci');
  final filt = filterBySubstring(white, '0000002');
  _check(filt.length == 1, 'filtro sottostringa atteso 1, trovati ${filt.length}');
  _check(filt.single.key.contains('0000002'), 'filtro deve contenere query');

  // Filtro case-insensitive e vuoto = tutto.
  final alpha = [ListEntryView(key: 'BANCA', dateAdded: _d(1))];
  _check(filterBySubstring(alpha, 'banc').length == 1, 'filtro case-insensitive');
  _check(filterBySubstring(white, '').length == 2, 'query vuota ritorna tutto');

  // Sort discendente per data.
  final unsorted = [
    ListEntryView(key: 'a', dateAdded: _d(1)),
    ListEntryView(key: 'b', dateAdded: _d(3)),
    ListEntryView(key: 'c', dateAdded: _d(2)),
  ];
  final sorted = sortByDateDesc(unsorted);
  _check(sorted[0].key == 'b', 'sort disc primo deve essere piu recente');
  _check(sorted[1].key == 'c', 'sort disc secondo');
  _check(sorted[2].key == 'a', 'sort disc ultimo piu vecchio');

  // Combinata su sezione: filtrate + ordinate disc.
  final combo = sectionFilteredSorted(
      lists, contacts, ManagedSection.whitelist, '333');
  _check(combo.length == 2, 'combo attese 2 voci');
  _check(!combo[0].dateAdded.isBefore(combo[1].dateAdded),
      'combo ordinata disc');

  // Blacklist e contatti raggiungibili.
  _check(sectionEntries(lists, contacts, ManagedSection.blacklist).length == 1,
      'blacklist 1 voce');
  _check(sectionEntries(lists, contacts, ManagedSection.contacts).length == 2,
      'contacts 2 voci');

  stdout.writeln('TP-801 PASSED: 3 liste, filtro sottostringa, sort disc');
}

DateTime _d(int day) => DateTime.utc(2026, 1, day);
