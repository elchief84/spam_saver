// TP-202: CRUD liste collassa i formati equivalenti dello stesso numero.
// Eseguibile con: dart test/tp_202_test.dart
import 'dart:io';
import '../src/domain/number_lists.dart';
import '../src/domain/phone_number.dart';

void _fail(String msg) {
  stderr.writeln('TP-202 FAILED: $msg');
  exit(1);
}

void _check(bool cond, String msg) {
  if (!cond) _fail(msg);
}

void main() {
  // I formati equivalenti devono indicare lo stesso numero.
  _check(areEquivalentNumbers('+393330000001', '00393330000001'),
      '+39/0039 devono equivalere');
  _check(areEquivalentNumbers('+393330000001', '+39 333 000 0001'),
      'spazi devono equivalere');
  _check(areEquivalentNumbers('+393330000001', '3330000001'),
      'formato nazionale deve equivalere a +39');
  _check(canonicalNumberKey('+393330000001') ==
      canonicalNumberKey('00393330000001'), 'chiave canonica 0039');
  _check(canonicalNumberKey('+393330000001') ==
      canonicalNumberKey('3330000001'), 'chiave canonica nazionale');
  _check(canonicalNumberKey('+393330000001') ==
      canonicalNumberKey('+39 333-000-0001'), 'chiave canonica spazi/tratti');

  // CRUD: inserito in un formato, ritrovato in formato equivalente.
  var lists = const NumberLists()
      .add(ManagedList.whitelist, '+393330000001');
  _check(lists.isWhitelisted('00393330000001'), 'lookup 0039 deve trovare');
  _check(lists.isWhitelisted('3330000001'), 'lookup nazionale deve trovare');
  _check(lists.isWhitelisted('+39 333 000 0001'), 'lookup spaziato deve trovare');
  _check(lists.entryIn(ManagedList.whitelist, '3330000001') != null,
      'entryIn equivalente deve trovare');

  // Remove in formato equivalente pulisce davvero.
  lists = lists.remove('0039 333 000 0001');
  _check(!lists.contains('+393330000001'), 'remove equivalente deve pulire');
  _check(!lists.contains('3330000001'), 'remove deve valere per ogni formato');

  // I sender alfanumerici distinti non devono collassare tra loro.
  var alpha = const NumberLists().add(ManagedList.blacklist, 'BANCA');
  _check(alpha.isBlacklisted('BANCA'), 'BANCA deve essere in blacklist');
  _check(!alpha.isBlacklisted('POSTA'), 'POSTA non deve collidere con BANCA');

  stdout.writeln('TP-202 PASSED: CRUD collassa formati equivalenti');
}
