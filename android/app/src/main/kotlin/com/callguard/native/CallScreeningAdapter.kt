package com.callguard.native

import android.os.Build
import android.telecom.Call
import android.telecom.CallScreeningService
import android.telecom.CallScreeningService.CallResponse

/**
 * SU-INF-01-01 — host onScreenCall, snapshot-only, fail-open (SRS-201/301).
 * Nessun I/O, rete o Room prima di respondToCall: solo snapshot in memoria.
 * Fallback AD-05: disconnect tentato, silence se rifiutato da OEM,
 * ramo sempre registrato nel ledger via [actuation].
 */
class CallGuardScreeningService : CallScreeningService() {

    override fun onScreenCall(details: Call.Details) {
        val t0 = android.os.SystemClock.elapsedRealtime()
        try {
            val raw = if (Build.VERSION.SDK_INT >= 29) {
                details.handle?.schemeSpecificPart
            } else {
                null
            }
            val verdict = ScreeningCore.decideSnapshotOnly(
                context = this,
                rawNumber = raw,
            )
            val response = when (verdict.action) {
                ScreeningAction.REJECT -> tryDisconnect()
                ScreeningAction.PASS -> passResponse()
            }
            respondToCall(details, response)
            val elapsed = android.os.SystemClock.elapsedRealtime() - t0
            ScreeningCore.afterDecisionOffPath(
                context = this,
                verdict = verdict,
                rawNumber = raw,
                elapsedMs = elapsed,
            )
        } catch (_: Exception) {
            // Fail-open: mai bloccare tutte le chiamate (SRS-1004).
            respondToCall(details, passResponse())
            DiagnosticsLogger.count("screening_internal_error")
        }
    }

    private fun tryDisconnect(): CallResponse {
        return try {
            CallResponse.Builder()
                .setDisallowCall(true)
                .setSkipCallLog(false)
                .setSkipNotification(true)
                .build()
        } catch (_: Exception) {
            // Fallback silence OEM (AD-05): registrato come silence_fallback.
            DiagnosticsLogger.count("actuation_silence_fallback")
            CallResponse.Builder()
                .setDisallowCall(false)
                .setSilenceCall(true)
                .build()
        }
    }

    private fun passResponse(): CallResponse {
        return CallResponse.Builder()
            .setDisallowCall(false)
            .build()
    }
}
