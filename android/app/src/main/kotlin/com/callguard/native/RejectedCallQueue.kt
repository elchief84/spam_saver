package com.callguard.native

import android.content.Context

/**
 * Coda off-path record + SMS (SU-APP-02-01/03-01 orchestrazione).
 * Chiamata solo dopo respondToCall; best-effort, mai blocca screening.
 */
object RejectedCallQueue {
    fun enqueue(context: Context, verdict: ScreeningVerdict, rawNumber: String?) {
        if (verdict.action != ScreeningAction.REJECT) return
        try {
            LocalStoreAdapter.insertRejectedCall(context, verdict, rawNumber)
        } catch (_: Exception) {
            DiagnosticsLogger.count("store_unwritable")
        }
    }
}
