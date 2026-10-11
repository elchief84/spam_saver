package com.callguard.native

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.telephony.SmsManager

/**
 * SU-INF-03-01 — invio SmsManager + mapping ledger, idempotenza per
 * event_id. Re-check eligibility prima di ogni send; nessun auto-retry.
 * Short-code/alpha/non-dialable: zero invii (guard ridondante).
 */
object SmsSenderAdapter {
    fun send(
        context: Context,
        eventId: String,
        destination: String,
        body: String,
        blacklistSmsEnabled: Boolean,
        decisionOrigin: String,
    ): String {
        if (!PhoneNumbers.isSmsDialable(destination)) return "skipped/non_dialable"
        if (decisionOrigin == "blacklist" && !blacklistSmsEnabled) {
            return "skipped/blacklisted"
        }
        return try {
            val sms = context.getSystemService(SmsManager::class.java)
                ?: SmsManager.getDefault()
            val sentIntent = PendingIntent.getBroadcast(
                context, eventId.hashCode(),
                Intent("com.callguard.SMS_SENT").putExtra("event_id", eventId),
                PendingIntent.FLAG_ONE_SHOT or PendingIntent.FLAG_IMMUTABLE,
            )
            if (body.length <= 160) {
                sms.sendTextMessage(destination, null, body, sentIntent, null)
            } else {
                val parts = sms.divideMessage(body)
                val intents = parts.map { sentIntent }
                sms.sendMultipartTextMessage(destination, null, parts, intents, null)
            }
            "sent"
        } catch (_: SecurityException) {
            "failed/no_permission"
        } catch (_: Exception) {
            "failed/radio_error"
        }
    }
}
