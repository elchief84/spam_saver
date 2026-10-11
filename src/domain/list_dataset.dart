// Modulo domain: dataset durevole delle liste con snapshot ricostruito
// in modo sincrono ad ogni commit e recupero con rollback.
// Puro Dart, zero dipendenze piattaforma.
// Proprieta':
// - ogni commit (add/move/remove) ricostruisce lo snapshot in modo
//   sincrono prima del return: il valore restituito contiene gia'
//   whitelist/blacklist aggiornate, nessun await, nessun I/O;
// - il dataset sopravvive a kill/reboot/upgrade tramite immagine
//   persistita su backing sincrono (mappa chiave->stringa);
// - scrittura interrotta: journal senza immagine consolidata -> al
//   prossimo open rollback al last-committed, mai stato parziale;
// - rollback esplicito: scarta il journal e ripristina l'immagine;
// - upgrade di schema: le immagini con versione piu' vecchia vengono
//   migrate preservando le voci e ricostruendo lo snapshot;
// - funzioni totali: mai throw, decode corrotto degrada a vuoto.

import 'number_lists.dart';
import 'screening_snapshot.dart';

/// Versione corrente dello schema persistito.
const int currentDatasetVersion = 2;

/// Chiavi del backing persistente.
const String datasetImageKey = 'dataset/image';
const String datasetJournalKey = 'dataset/journal';

ScreeningSnapshot _snapshotFrom(NumberLists lists, List<String> contacts) {
  return ScreeningSnapshot(
    contacts: List<String>.unmodifiable(contacts),
    whitelist: List<String>.unmodifiable(lists.whitelist.keys.toList()),
    blacklist: List<String>.unmodifiable(lists.blacklist.keys.toList()),
  );
}

/// Dataset immutabile: liste + snapshot congelato + versione schema.
/// Ogni commit restituisce un nuovo dataset con snapshot gia' ricostruito.
class ListDataset {
  final NumberLists lists;
  final ScreeningSnapshot snapshot;
  final List<String> contacts;
  final int version;

  const ListDataset({
    required this.lists,
    required this.snapshot,
    required this.contacts,
    required this.version,
  });

  factory ListDataset.empty() {
    const lists = NumberLists();
    return ListDataset(
      lists: lists,
      snapshot: _snapshotFrom(lists, const []),
      contacts: const [],
      version: currentDatasetVersion,
    );
  }

  /// Ricostruisce lo snapshot dalle liste, in modo sincrono.
  ListDataset rebuildSnapshot() {
    return ListDataset(
      lists: lists,
      snapshot: _snapshotFrom(lists, contacts),
      contacts: contacts,
      version: version,
    );
  }

  /// Commit sincrono di add: snapshot ricostruito prima del return.
  ListDataset commitAdd(ManagedList list, String raw, {DateTime? at}) {
    final next = lists.add(list, raw, at: at);
    return ListDataset(
      lists: next,
      snapshot: _snapshotFrom(next, contacts),
      contacts: contacts,
      version: version,
    );
  }

  /// Commit sincrono di move: snapshot ricostruito prima del return.
  ListDataset commitMove(String raw, {required ManagedList to, DateTime? at}) {
    final next = lists.moveTo(raw, to: to, at: at);
    return ListDataset(
      lists: next,
      snapshot: _snapshotFrom(next, contacts),
      contacts: contacts,
      version: version,
    );
  }

  /// Commit sincrono di remove: snapshot ricostruito prima del return.
  ListDataset commitRemove(String raw) {
    final next = lists.remove(raw);
    return ListDataset(
      lists: next,
      snapshot: _snapshotFrom(next, contacts),
      contacts: contacts,
      version: version,
    );
  }

  /// Serializzazione sincrona su mappa di stringhe (totale).
  Map<String, String> toMap() {
    final white = lists.whitelist.values
        .map((e) => '${e.numberKey}|${e.dateAdded.toUtc().toIso8601String()}')
        .join(';');
    final black = lists.blacklist.values
        .map((e) => '${e.numberKey}|${e.dateAdded.toUtc().toIso8601String()}')
        .join(';');
    return <String, String>{
      'version': '$version',
      'whitelist': white,
      'blacklist': black,
      'contacts': contacts.join(';'),
    };
  }

  /// Deserializzazione totale con migrate: mai throw, input corrotto
  /// degrada a dataset vuoto con snapshot coerente.
  static ListDataset fromMap(Map<String, String> map) {
    try {
      final rawVersion = int.tryParse(map['version'] ?? '') ?? 1;
      if (rawVersion > currentDatasetVersion) {
        // Versione futura: degrada alla corrente con migrate delle voci.
      }
      var lists = const NumberLists();
      lists = _restoreSide(lists, ManagedList.whitelist, map['whitelist'] ?? '');
      lists = _restoreSide(lists, ManagedList.blacklist, map['blacklist'] ?? '');
      final contacts = (map['contacts'] ?? '').isEmpty
          ? <String>[]
          : (map['contacts'] ?? '').split(';').where((s) => s.isNotEmpty).toList();
      // Upgrade: voci preservate, versione portata alla corrente,
      // snapshot ricostruito in modo sincrono.
      return ListDataset(
        lists: lists,
        snapshot: _snapshotFrom(lists, contacts),
        contacts: List<String>.unmodifiable(contacts),
        version: currentDatasetVersion,
      );
    } catch (_) {
      return ListDataset.empty();
    }
  }

  static NumberLists _restoreSide(
      NumberLists lists, ManagedList side, String packed) {
    if (packed.isEmpty) return lists;
    var out = lists;
    for (final chunk in packed.split(';')) {
      if (chunk.isEmpty) continue;
      final sep = chunk.lastIndexOf('|');
      final key = sep < 0 ? chunk : chunk.substring(0, sep);
      final stampRaw = sep < 0 ? '' : chunk.substring(sep + 1);
      final at = DateTime.tryParse(stampRaw)?.toUtc() ?? DateTime.utc(2026, 1, 1);
      if (key.isEmpty) continue;
      out = out.add(side, key, at: at);
    }
    return out;
  }

  /// Codifica sincrona su singola stringa (round-trip con [decode]).
  String encode() {
    final m = toMap();
    String esc(String s) => s.replaceAll('%', '%25').replaceAll('#', '%23').replaceAll('=', '%3D');
    return 'v=${m['version']}&w=${esc(m['whitelist'] ?? '')}'
        '&b=${esc(m['blacklist'] ?? '')}&c=${esc(m['contacts'] ?? '')}';
  }

  /// Decodifica totale: mai throw, stringa corrotta -> dataset vuoto.
  static ListDataset decode(String raw) {
    try {
      String unesc(String s) =>
          s.replaceAll('%3D', '=').replaceAll('%23', '#').replaceAll('%25', '%');
      final m = <String, String>{};
      for (final part in raw.split('&')) {
        final i = part.indexOf('=');
        if (i < 0) continue;
        m[part.substring(0, i)] = unesc(part.substring(i + 1));
      }
      return fromMap(<String, String>{
        'version': m['v'] ?? '',
        'whitelist': m['w'] ?? '',
        'blacklist': m['b'] ?? '',
        'contacts': m['c'] ?? '',
      });
    } catch (_) {
      return ListDataset.empty();
    }
  }
}

/// Store durevole sincrono sopra un backing chiave->stringa.
/// Il backing simula il disco: sopravvive a kill/reboot (nuovo oggetto
/// sullo stesso backing), upgrade (migrate) e scrittura interrotta
/// (journal senza immagine -> rollback all'open).
class DurableListStore {
  final Map<String, String> backing;
  final ListDataset dataset;

  const DurableListStore._(this.backing, this.dataset);

  /// Crea o riapre lo store sul [backing]: se esiste un'immagine la
  /// carica (con migrate), se esiste un journal pendente senza immagine
  /// consolidata esegue rollback (scarta il journal). Totale, sincrono.
  factory DurableListStore.create(Map<String, String> backing) {
    return DurableListStore._(backing, const _Opener().open(backing));
  }

  /// Riapertura esplicita (reboot): stessa semantica di [create].
  DurableListStore open() {
    return DurableListStore._(backing, const _Opener().open(backing));
  }

  int get version => dataset.version;
  NumberLists get lists => dataset.lists;
  ScreeningSnapshot get snapshot => dataset.snapshot;

  DurableListStore _persist(ListDataset next, String op) {
    // Protocollo sincrono: journal -> immagine -> pulizia journal,
    // tutto prima del return, nessun punto di await.
    backing[datasetJournalKey] = op;
    backing[datasetImageKey] = next.encode();
    backing.remove(datasetJournalKey);
    return DurableListStore._(backing, next);
  }

  /// Commit add durevole con rebuild snapshot sincrono prima del return.
  DurableListStore commitAdd(ManagedList list, String raw, {DateTime? at}) {
    final next = dataset.commitAdd(list, raw, at: at);
    return _persist(next, 'add:${list.name}:$raw');
  }

  /// Commit move durevole con rebuild snapshot sincrono prima del return.
  DurableListStore commitMove(String raw,
      {required ManagedList to, DateTime? at}) {
    final next = dataset.commitMove(raw, to: to, at: at);
    return _persist(next, 'move:${to.name}:$raw');
  }

  /// Commit remove durevole con rebuild snapshot sincrono prima del return.
  DurableListStore commitRemove(String raw) {
    final next = dataset.commitRemove(raw);
    return _persist(next, 'remove:$raw');
  }

  /// Simula una scrittura interrotta (crash dopo il journal, prima
  /// dell'immagine): lascia il journal pendente senza consolidare.
  /// Solo per test: il prossimo [open] deve fare rollback.
  void beginInterruptedWriteForTest(String op) {
    backing[datasetJournalKey] = op;
  }

  /// Rollback esplicito: scarta il journal pendente e ripristina
  /// l'ultima immagine consolidata (o vuoto). Sincrono, totale.
  DurableListStore rollback() {
    backing.remove(datasetJournalKey);
    final raw = backing[datasetImageKey];
    final recovered =
        raw == null ? ListDataset.empty() : ListDataset.decode(raw);
    return DurableListStore._(backing, recovered);
  }

  /// True se esiste un journal pendente (scrittura interrotta).
  bool get hasPendingJournal => backing.containsKey(datasetJournalKey);
}

class _Opener {
  const _Opener();

  ListDataset open(Map<String, String> backing) {
    final raw = backing[datasetImageKey];
    final base = raw == null ? ListDataset.empty() : ListDataset.decode(raw);
    // Journal pendente senza immagine consolidata successiva:
    // rollback, mai stato parziale.
    if (backing.containsKey(datasetJournalKey)) {
      backing.remove(datasetJournalKey);
    }
    return base;
  }
}
