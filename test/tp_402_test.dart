// TP-402: move preserva date_added originale.
// Eseguibile con: dart test/tp_402_test.dart
import 'dart:io';
import '../src/domain/number_lists.dart';

void _fail(String msg) {
  stderr.writeln('TP-402 FAILED: $msg');
  exit(1);
}

void _check(bool cond, String msg) {
  if (!cond) _fail(msg);
}

void main() {
  final t1 = DateTime.utc(2026, 1, 1, 12, 0, 0);

  // Inserimento con data nota, poi move: la data si conserva.
  var lists = const NumberLists()
      .add(ManagedList.whitelist, '+393330000002', at: t1);
  final before = lists.entryIn(ManagedList.whitelist, '+393330000002');
  _check(before != null && before.dateAdded == t1, 'date_added iniziale deve essere $t1');

  lists = lists.moveTo('+393330000002', to: ManagedList.blacklist);
  final moved = lists.entryIn(ManagedList.blacklist, '+393330000002');
  _check(moved != null, 'dopo move il numero deve essere in blacklist');
  _check(moved!.dateAdded == t1,
      'move deve preservare date_added $t1, trovato ${moved.dateAdded}');
  _check(lists.entryIn(ManagedList.whitelist, '+393330000002') == null,
      'dopo move il numero non deve restare in whitelist');

  // Move inverso: la data si conserva ancora.
  lists = lists.moveTo('+393330000002', to: ManagedList.whitelist);
  final back = lists.entryIn(ManagedList.whitelist, '+393330000002');
  _check(back != null && back.dateAdded == t1,
      'secondo move deve preservare date_added $t1');

  // Re-add nella stessa lista: la data non si azzera.
  lists = lists.add(ManagedList.whitelist, '+393330000002');
  final same = lists.entryIn(ManagedList.whitelist, '+393330000002');
  _check(same != null && same.dateAdded == t1,
      're-add stessa lista deve tenere date_added $t1');

  stdout.writeln('TP-402 PASSED: move preserva date_added $t1');
}
