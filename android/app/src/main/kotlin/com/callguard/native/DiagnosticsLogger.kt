package com.callguard.native

import android.content.Context
import android.util.Log
import java.security.MessageDigest

/**
 * SU-INF-08-01 — diagnostica con scrub PII obbligatorio (SRS-1003).
 * Allowlist chiavi; valori con cifre lunghe -> hash8; body/numeri mai.
 * Contatori senza identificatori per RSK-102/107.
 */
object DiagnosticsLogger {
    private const val TAG = "CallGuard"
    private val allowedKeys = setOf(
        "verdict_origin", "actuation", "sms_status", "reason",
        "elapsed_ms", "os_api", "event_id",
    )
    private val counters = mutableMapOf<String, Long>()

    fun event(name: String, attrs: Map<String, String>) {
        val scrubbed = attrs
            .filterKeys { it in allowedKeys }
            .mapValues { scrub(it.value) }
        Log.d(TAG, "$name $scrubbed")
    }

    fun count(counter: String) {
        counters[counter] = (counters[counter] ?: 0L) + 1
    }

    fun scrub(value: String): String {
        if (value.length > 160) return "<redacted>"
        if (Regex("""\+?[0-9]{6,}""").containsMatchIn(value)) {
            val digest = MessageDigest.getInstance("SHA-256")
                .digest(value.toByteArray())
            return digest.take(4).joinToString("") { "%02x".format(it) }
        }
        return value
    }

    @Suppress("UNUSED_PARAMETER")
    fun attachContext(context: Context) = Unit
}
