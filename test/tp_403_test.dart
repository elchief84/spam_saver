// TP-403: dataset liste sopravvive a kill/reboot/upgrade,
// scrittura interrotta con rollback, mai stato parziale.
// Eseguibile con: dart test/tp_403_test.dart
import 'dart:io';
import '../src/domain/list_dataset.dart';
import '../src/domain/number_lists.dart';

void _fail(String msg) {
  stderr.writeln('TP-403 FAILED: $msg');
  exit(1);
}

void _check(bool cond, String msg) {
  if (!cond) _fail(msg);
}

void main() {
  // Commit iniziale su backing persistente.
  final backing = <String, String>{};
  var store = DurableListStore.create(backing);
  store = store.commitAdd(ManagedList.whitelist, '+393330000001');
  store = store.commitAdd(ManagedList.blacklist, '+393330000002');
  _check(store.lists.isWhitelisted('+393330000001'), 'whitelist attesa');
  _check(store.lists.isBlacklisted('3330000002'), 'blacklist attesa equivalente');

  // Kill: nuovo oggetto sullo stesso backing, dati sopravvivono.
  var killed = DurableListStore.create(backing);
  _check(killed.lists.isWhitelisted('00393330000001'), 'kill: whitelist sopravvive');
  _check(killed.lists.isBlacklisted('+393330000002'), 'kill: blacklist sopravvive');
  _check(killed.snapshot.inWhitelist('+393330000001'), 'kill: snapshot whitelist coerente');
  _check(killed.snapshot.inBlacklist('+393330000002'), 'kill: snapshot blacklist coerente');

  // Reboot: open esplicito, dati sopravvivono.
  var rebooted = killed.open();
  _check(rebooted.lists.isWhitelisted('+393330000001'), 'reboot: whitelist sopravvive');
  _check(rebooted.lists.isBlacklisted('+393330000002'), 'reboot: blacklist sopravvive');

  // Upgrade: immagine con versione vecchia migra preservando le voci.
  final old = ListDataset.empty()
      .commitAdd(ManagedList.whitelist, '+393330000009')
      .toMap();
  old['version'] = '1';
  final backingOld = <String, String>{
    datasetImageKey: ListDataset.fromMap(old).encode(),
  };
  // Forza versione 1 nell'immagine.
  backingOld[datasetImageKey] =
      backingOld[datasetImageKey]!.replaceFirst('v=2', 'v=1');
  var upgraded = DurableListStore.create(backingOld);
  _check(upgraded.version == currentDatasetVersion, 'upgrade: versione portata a $currentDatasetVersion');
  _check(upgraded.lists.isWhitelisted('+393330000009'), 'upgrade: voci preservate');
  _check(upgraded.snapshot.inWhitelist('+393330000009'), 'upgrade: snapshot ricostruito');

  // Scrittura interrotta: journal senza immagine -> rollback al prossimo open.
  var wstore = DurableListStore.create(<String, String>{});
  wstore = wstore.commitAdd(ManagedList.whitelist, '+393330000001');
  wstore.beginInterruptedWriteForTest('add:blacklist:+393330000099');
  _check(wstore.hasPendingJournal, 'journal pendente atteso');
  final recovered = wstore.open();
  _check(!recovered.hasPendingJournal, 'open deve pulire il journal (rollback)');
  _check(recovered.lists.isWhitelisted('+393330000001'), 'rollback: whitelist consolidata resta');
  _check(!recovered.lists.isBlacklisted('+393330000099'), 'rollback: scrittura interrotta mai consolidata');
  _check(!recovered.lists.contains('+393330000099'), 'rollback: mai stato parziale');

  // Rollback esplicito dopo scrittura interrotta.
  var rstore = DurableListStore.create(<String, String>{});
  rstore = rstore.commitAdd(ManagedList.blacklist, '+393330000002');
  rstore.beginInterruptedWriteForTest('remove:+393330000002');
  rstore = rstore.rollback();
  _check(rstore.lists.isBlacklisted('+393330000002'), 'rollback esplicito: voce consolidata resta');
  _check(!rstore.hasPendingJournal, 'rollback esplicito: journal pulito');

  stdout.writeln('TP-403 PASSED: dataset kill/reboot/upgrade/interrotta/rollback');
}
