package com.callguard.native

import android.content.Context
import android.provider.Telephony

/**
 * SU-INF-04-01 — query inbox solo foreground, scoped a watermark,
 * cap 200 newest-first. Mai background listener in v1 (AD-04).
 * Negato -> vuoto + PERMISSION_DENIED_SMS_READ.
 */
object SmsInboxReaderAdapter {
    data class Row(
        val providerMsgId: String,
        val address: String,
        val date: Long,
        val body: String,
    )

    fun querySince(context: Context, watermarkMs: Long, limit: Int = 200): List<Row> {
        return try {
            val out = mutableListOf<Row>()
            context.contentResolver.query(
                Telephony.Sms.Inbox.CONTENT_URI,
                arrayOf("_id", "thread_id", "address", "date", "body"),
                "date > ?",
                arrayOf(watermarkMs.toString()),
                "date DESC LIMIT $limit",
            )?.use { c ->
                val idI = c.getColumnIndexOrThrow("_id")
                val thI = c.getColumnIndexOrThrow("thread_id")
                val adI = c.getColumnIndexOrThrow("address")
                val daI = c.getColumnIndexOrThrow("date")
                val boI = c.getColumnIndexOrThrow("body")
                while (c.moveToNext() && out.size < limit) {
                    out.add(
                        Row(
                            providerMsgId = "${c.getString(idI)}:${c.getString(thI)}",
                            address = c.getString(adI) ?: "",
                            date = c.getLong(daI),
                            body = c.getString(boI) ?: "",
                        ),
                    )
                }
            }
            out
        } catch (_: Exception) {
            emptyList()
        }
    }
}
