// Verifica inbox: solo foreground, watermark cap200, dedup provider_msg_id,
// senza lettura zero letture con vista accesso mancante.
// Eseguibile con: dart test/sms_inbox_test.dart
import 'dart:io';
import '../src/domain/sms_inbox.dart';

void _fail(String msg) {
  stderr.writeln('SMS-INBOX FAILED: $msg');
  exit(1);
}

void _check(bool cond, String msg) {
  if (!cond) _fail(msg);
}

List<ProviderSms> _rows(int n, {int start = 1}) {
  return List.generate(
      n,
      (i) => ProviderSms(
          rowId: start + i,
          providerMsgId: 'p${start + i}',
          address: '+393330000030'));
}

void main() {
  // Senza permesso: zero letture + vista accesso mancante.
  var r = readSmsInbox(
    state: const SmsInboxState(),
    isForeground: true,
    hasSmsRead: false,
    rows: _rows(5),
  );
  _check(r.messages.isEmpty, 'senza permesso zero letture attese');
  _check(r.accessMissing, 'senza permesso vista accesso mancante');
  _check(r.nextWatermark == 0, 'senza permesso watermark invariato');

  // Solo foreground: background => zero letture, watermark invariato.
  r = readSmsInbox(
    state: const SmsInboxState(),
    isForeground: false,
    hasSmsRead: true,
    rows: _rows(5),
  );
  _check(r.messages.isEmpty, 'background zero letture attese');
  _check(!r.accessMissing, 'background non e accesso mancante');
  _check(r.nextWatermark == 0, 'background watermark invariato');

  // Scoped watermark: solo rowId > watermark.
  r = readSmsInbox(
    state: const SmsInboxState(watermark: 3),
    isForeground: true,
    hasSmsRead: true,
    rows: _rows(5),
  );
  _check(r.messages.length == 2, 'watermark 3 su 5 righe => 2 attese, trovate ${r.messages.length}');
  _check(r.nextWatermark == 5, 'watermark deve avanzare a 5');

  // Cap 200: 250 righe => solo 200.
  r = readSmsInbox(
    state: const SmsInboxState(),
    isForeground: true,
    hasSmsRead: true,
    rows: _rows(250),
  );
  _check(r.messages.length == 200, 'cap200 atteso, trovate ${r.messages.length}');
  _check(r.nextWatermark == 200, 'watermark deve fermarsi a 200');

  // Dedup provider_msg_id dentro batch e contro stato.
  final dup = <ProviderSms>[
    const ProviderSms(rowId: 1, providerMsgId: 'dup', address: 'a'),
    const ProviderSms(rowId: 2, providerMsgId: 'dup', address: 'a'),
    const ProviderSms(rowId: 3, providerMsgId: 'unico', address: 'a'),
  ];
  r = readSmsInbox(
    state: const SmsInboxState(),
    isForeground: true,
    hasSmsRead: true,
    rows: dup,
  );
  _check(r.messages.length == 2, 'dedup batch => 2 attese, trovate ${r.messages.length}');
  // Secondo giro: nulla di nuovo.
  final r2 = readSmsInbox(
    state: r.state,
    isForeground: true,
    hasSmsRead: true,
    rows: dup,
  );
  _check(r2.messages.isEmpty, 're-lettura stessi id => zero messaggi');

  stdout.writeln('SMS-INBOX PASSED: foreground-only, watermark cap200, dedup provider_msg_id, no-read zero');
}
