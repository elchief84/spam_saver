package com.callguard.native

import android.content.Context

enum class ScreeningAction { PASS, REJECT }

data class ScreeningVerdict(
    val action: ScreeningAction,
    val origin: String,
)

/**
 * Nucleo decisionale snapshot-only (SU-APP-01-01 + SU-DOM-02-01).
 * Legge solo set in memoria precaricati; nessun I/O prima del return.
 * Precedenza: no-role -> anonimo-pass -> blacklist -> contacts/whitelist
 * -> unknown-reject. Record + SMS schedulati off-path.
 */
object ScreeningCore {
    @Volatile var blacklist: Set<String> = emptySet()
    @Volatile var whitelist: Set<String> = emptySet()
    @Volatile var contacts: Set<String> = emptySet()

    fun decideSnapshotOnly(context: Context, rawNumber: String?): ScreeningVerdict {
        val roleHeld = ProtectionState.hasRole(context)
        if (!roleHeld) {
            DiagnosticsLogger.count("role_missing")
            return ScreeningVerdict(ScreeningAction.PASS, "no_role")
        }
        val normalized = PhoneNumbers.normalizeOrNull(rawNumber)
            ?: return ScreeningVerdict(ScreeningAction.PASS, "anonymous")
        if (blacklist.contains(normalized)) {
            return ScreeningVerdict(ScreeningAction.REJECT, "blacklist")
        }
        if (contacts.contains(normalized) || whitelist.contains(normalized)) {
            return ScreeningVerdict(ScreeningAction.PASS, "allow")
        }
        return ScreeningVerdict(ScreeningAction.REJECT, "unknown")
    }

    fun afterDecisionOffPath(
        context: Context,
        verdict: ScreeningVerdict,
        rawNumber: String?,
        elapsedMs: Long,
    ) {
        DiagnosticsLogger.event(
            "screened",
            mapOf(
                "verdict_origin" to verdict.origin,
                "elapsed_ms" to elapsedMs.toString(),
            ),
        )
        // Record + SMS eligibility fuori dal path: coda lavoro best-effort.
        RejectedCallQueue.enqueue(context, verdict, rawNumber)
    }

    fun rebuildSnapshot(black: Set<String>, white: Set<String>, cont: Set<String>) {
        blacklist = black
        whitelist = white
        contacts = cont
    }
}
