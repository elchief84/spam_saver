// TP-401: mai doppia appartenenza whitelist/blacklist.
// Eseguibile con: dart test/tp_401_test.dart
import 'dart:io';
import '../src/domain/number_lists.dart';

void _fail(String msg) {
  stderr.writeln('TP-401 FAILED: $msg');
  exit(1);
}

void _check(bool cond, String msg) {
  if (!cond) _fail(msg);
}

void _checkExclusive(NumberLists lists, String raw, String label) {
  if (lists.isWhitelisted(raw) && lists.isBlacklisted(raw)) {
    _fail('$label: doppia appartenenza per "$raw"');
  }
}

void main() {
  var lists = const NumberLists();
  lists = lists.add(ManagedList.whitelist, '+393330000001');
  _check(lists.isWhitelisted('+393330000001'), 'numero deve essere in whitelist');
  _check(!lists.isBlacklisted('+393330000001'), 'numero non deve essere in blacklist');

  // Aggiunta alla lista opposta: appartenenza esclusiva.
  lists = lists.add(ManagedList.blacklist, '+393330000001');
  _check(lists.isBlacklisted('+393330000001'), 'numero deve passare in blacklist');
  _check(!lists.isWhitelisted('+393330000001'), 'numero deve uscire da whitelist');
  _checkExclusive(lists, '+393330000001', 'dopo add opposto');

  // Variante di formato dello stesso numero: resta esclusiva.
  lists = lists.add(ManagedList.whitelist, '+39 333 000 0001');
  _check(lists.isWhitelisted('+393330000001'), 'variante formato deve risolvere in whitelist');
  _check(!lists.isBlacklisted('+393330000001'), 'variante formato deve uscire da blacklist');
  _checkExclusive(lists, '+39 333 000 0001', 'dopo variante formato');

  // moveTo incrociato: mai doppia appartenenza.
  lists = lists.moveTo('+393330000001', to: ManagedList.blacklist);
  _check(lists.isBlacklisted('+393330000001'), 'moveTo blacklist atteso');
  _check(!lists.isWhitelisted('+393330000001'), 'moveTo deve togliere da whitelist');
  _checkExclusive(lists, '+393330000001', 'dopo moveTo');

  // remove pulisce entrambe.
  lists = lists.remove('+393330000001');
  _check(!lists.contains('+393330000001'), 'remove deve togliere da entrambe');

  stdout.writeln('TP-401 PASSED: appartenenza sempre esclusiva');
}
