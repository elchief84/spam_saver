// Verifica mapping esiti piattaforma + zero invii short-code.
// Eseguibile con: dart test/sms_result_test.dart
import 'dart:io';
import '../src/domain/sms_dispatch.dart';
import '../src/domain/sms_result.dart';

void _fail(String msg) {
  stderr.writeln('SMS-RESULT FAILED: $msg');
  exit(1);
}

void _check(bool cond, String msg) {
  if (!cond) _fail(msg);
}

void main() {
  _check(mapSmsPlatformDelivery(SmsPlatformDelivery.success) == SmsSendOutcome.sent,
      'SUCCESS deve mappare sent');
  _check(mapSmsPlatformDelivery(SmsPlatformDelivery.noService) == SmsSendOutcome.failed,
      'NO_SERVICE deve mappare failed');
  _check(mapSmsPlatformDelivery(SmsPlatformDelivery.genericFailure) == SmsSendOutcome.failed,
      'GENERIC_FAILURE deve mappare failed');
  _check(mapSmsPlatformDelivery(SmsPlatformDelivery.radioOff) == SmsSendOutcome.failed,
      'RADIO_OFF deve mappare failed');
  _check(mapSmsPlatformCodeName('SUCCESS') == SmsSendOutcome.sent,
      'nome SUCCESS deve dare sent');
  _check(mapSmsPlatformCodeName('NO_SERVICE') == SmsSendOutcome.failed,
      'nome NO_SERVICE deve dare failed');
  _check(mapSmsPlatformCodeName('other') == SmsSendOutcome.failed,
      'nome ignoto deve dare failed');
  // Zero invii a short-code / alfanumerici / non composti.
  for (final raw in <String>['40400', 'BANCA', '+39 ABC', '']) {
    _check(mustSuppressSmsSend(raw), '"$raw" deve essere soppresso (zero invii)');
  }
  _check(!mustSuppressSmsSend('+393330000030'),
      '+393330000030 non deve essere soppresso');
  stdout.writeln('SMS-RESULT PASSED: success->sent, no_service->failed, short-code zero invii');
}
