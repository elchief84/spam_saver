// TP-705: ogni commit liste ricostruisce lo snapshot in modo sincrono
// prima del return, senza await ne' I/O.
// Eseguibile con: dart test/tp_705_test.dart
import 'dart:io';
import '../src/domain/list_dataset.dart';
import '../src/domain/number_lists.dart';

void _fail(String msg) {
  stderr.writeln('TP-705 FAILED: $msg');
  exit(1);
}

void _check(bool cond, String msg) {
  if (!cond) _fail(msg);
}

void main() {
  // commitAdd: snapshot gia' aggiornato al return (stesso statement).
  var ds = ListDataset.empty()
      .commitAdd(ManagedList.whitelist, '+393330000001');
  _check(ds.snapshot.inWhitelist('+393330000001'), 'commitAdd: snapshot whitelist sincrono');
  _check(ds.snapshot.inWhitelist('3330000001'), 'commitAdd: snapshot per formato equivalente');
  _check(!ds.snapshot.inBlacklist('+393330000001'), 'commitAdd: mai in blacklist');

  // commitMove: snapshot ricostruito prima del return.
  ds = ds.commitMove('+393330000001', to: ManagedList.blacklist);
  _check(ds.snapshot.inBlacklist('+393330000001'), 'commitMove: snapshot blacklist sincrono');
  _check(ds.snapshot.inBlacklist('00393330000001'), 'commitMove: equivalente sincrono');
  _check(!ds.snapshot.inWhitelist('+393330000001'), 'commitMove: uscita whitelist sincrona');

  // commitRemove: snapshot ricostruito prima del return.
  ds = ds.commitRemove('3330000001');
  _check(!ds.snapshot.inBlacklist('+393330000001'), 'commitRemove: snapshot pulito sincrono');
  _check(!ds.snapshot.inWhitelist('+393330000001'), 'commitRemove: whitelist resta pulita');
  _check(!ds.lists.contains('+393330000001'), 'commitRemove: liste pulite');

  // rebuildSnapshot esplicito e' sincrono e coerente.
  final rebuilt = ds.commitAdd(ManagedList.blacklist, '+393330000002').rebuildSnapshot();
  _check(rebuilt.snapshot.inBlacklist('+393330000002'), 'rebuild: snapshot coerente');

  // Store durevole: ogni commit persiste e ha snapshot sincrono al return.
  final backing = <String, String>{};
  var store = DurableListStore.create(backing);
  store = store.commitAdd(ManagedList.whitelist, '+393330000003');
  _check(store.snapshot.inWhitelist('+393330000003'), 'store commitAdd: snapshot sincrono');
  store = store.commitMove('+393330000003', to: ManagedList.blacklist);
  _check(store.snapshot.inBlacklist('+393330000003'), 'store commitMove: snapshot sincrono');
  _check(!store.snapshot.inWhitelist('+393330000003'), 'store commitMove: uscita sincrona');
  store = store.commitRemove('+393330000003');
  _check(!store.snapshot.inBlacklist('+393330000003'), 'store commitRemove: snapshot sincrono');

  // Nessun Future: i commit sono valori puri gia' pronti al return.
  ListDataset syncCheck = ListDataset.empty();
  syncCheck = syncCheck.commitAdd(ManagedList.whitelist, '+393330000004');
  final inSnap = syncCheck.snapshot.inWhitelist('+393330000004');
  _check(inSnap, 'commit sincrono: nessun await per vedere lo snapshot');

  stdout.writeln('TP-705 PASSED: ogni commit rebuild snapshot sincrono prima del return');
}
