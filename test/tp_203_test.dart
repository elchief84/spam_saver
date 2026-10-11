// TP-203: mai doppia appartenenza, anche tra formati equivalenti;
// lo spostamento conserva il date_added originale.
// Eseguibile con: dart test/tp_203_test.dart
import 'dart:io';
import '../src/domain/number_lists.dart';

void _fail(String msg) {
  stderr.writeln('TP-203 FAILED: $msg');
  exit(1);
}

void _check(bool cond, String msg) {
  if (!cond) _fail(msg);
}

void _checkExclusive(NumberLists lists, String probe, String label) {
  if (lists.isWhitelisted(probe) && lists.isBlacklisted(probe)) {
    _fail('$label: doppia appartenenza per "$probe"');
  }
}

void main() {
  final t1 = DateTime.utc(2026, 2, 1, 9, 0, 0);

  // Inserito nazionale in whitelist, riaggiunto +39 in blacklist:
  // deve spostarsi, mai appartenere a entrambe.
  var lists = const NumberLists()
      .add(ManagedList.whitelist, '3330000002', at: t1);
  lists = lists.add(ManagedList.blacklist, '+393330000002');
  _check(lists.isBlacklisted('3330000002'), 'deve passare in blacklist');
  _check(lists.isBlacklisted('+393330000002'), 'lookup +39 deve trovare');
  _check(!lists.isWhitelisted('3330000002'), 'deve uscire da whitelist');
  _check(!lists.isWhitelisted('00393330000002'), 'uscita in ogni formato');
  _checkExclusive(lists, '3330000002', 'dopo add equivalente opposto');
  _checkExclusive(lists, '+393330000002', 'dopo add equivalente opposto');

  // Lo spostamento tra formati conserva il date_added originale.
  final moved = lists.entryIn(ManagedList.blacklist, '00393330000002');
  _check(moved != null && moved.dateAdded == t1,
      'move tra formati deve preservare date_added $t1');

  // moveTo esplicito in formato diverso: ancora esclusivo e datato.
  lists = lists.moveTo('+39 333 000 0002', to: ManagedList.whitelist);
  _check(lists.isWhitelisted('+393330000002'), 'moveTo whitelist atteso');
  _check(!lists.isBlacklisted('3330000002'), 'moveTo toglie da blacklist');
  _checkExclusive(lists, '3330000002', 'dopo moveTo equivalente');
  final back = lists.entryIn(ManagedList.whitelist, '3330000002');
  _check(back != null && back.dateAdded == t1,
      'moveTo deve tenere date_added $t1, trovato ${back?.dateAdded}');

  stdout.writeln('TP-203 PASSED: mai doppia appartenenza, date_added $t1 conservato');
}
