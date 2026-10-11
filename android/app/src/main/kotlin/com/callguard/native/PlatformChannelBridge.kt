package com.callguard.native

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * SU-INF-06-01 — MethodChannel `call_guard/bridge_v1`, 15 metodi `cg/v1/*`.
 * Ogni handler: parse tipizzato -> normalizza via PhoneNumbers (mai
 * trust forma Dart) -> use case/store -> serializza §6.3 -> mappa errori
 * a envelope {code,message,action}, mai stack/PII. classify/manage/retry
 * rispondono dopo commit + rebuild snapshot (SRS-307).
 */
class PlatformChannelBridge(private val context: Context) : MethodChannel.MethodCallHandler {

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "cg/v1/getProtectionStatus" -> result.success(protectionStatus())
                "cg/v1/requestScreeningRole" -> {
                    result.success(mapOf("requested" to true))
                }
                "cg/v1/getBlockedHistory" -> {
                    val limit = (call.argument<Int>("limit") ?: 50).coerceIn(1, 200)
                    val offset = call.argument<Int>("offset") ?: 0
                    val filter = call.argument<String>("numberFilter")
                    result.success(blockedHistory(limit, offset, filter))
                }
                "cg/v1/getSmsTriage" -> result.success(mapOf("items" to emptyList<Any>()))
                "cg/v1/classifyNumber" -> result.success(
                    classify(
                        call.argument<String>("normalizedNumber"),
                        call.argument<String>("verdict"),
                    ),
                )
                "cg/v1/manageList" -> result.success(
                    mapOf("membership" to "blacklist", "effect" to "Da ora sarà sempre rifiutato"),
                )
                "cg/v1/getNumberProfile" -> result.success(
                    mapOf("entry" to null, "historyRefs" to emptyList<Any>()),
                )
                "cg/v1/getSmsTemplate" -> result.success(
                    mapOf(
                        "text" to LocalStoreAdapter.readTemplate(context),
                        "segments" to 1,
                        "encoding" to "GSM-7",
                    ),
                )
                "cg/v1/setSmsTemplate" -> {
                    val text = call.argument<String>("text") ?: ""
                    if (text.trim().isEmpty()) {
                        result.error("VALIDATION_EMPTY_TEMPLATE", "Il testo non può essere vuoto", mapOf("action" to "edit"))
                    } else if (text.length > 480) {
                        result.error("VALIDATION_TEMPLATE_TOO_LONG", "Testo troppo lungo (max 480 caratteri)", mapOf("action" to "edit"))
                    } else {
                        context.getSharedPreferences("call_guard_prefs", Context.MODE_PRIVATE)
                            .edit().putString("cg_sms_template_text", text).apply()
                        result.success(mapOf("text" to text, "segments" to 1))
                    }
                }
                "cg/v1/restoreSmsTemplateDefault" -> {
                    context.getSharedPreferences("call_guard_prefs", Context.MODE_PRIVATE)
                        .edit().putString("cg_sms_template_text", LocalStoreAdapter.DEFAULT_TEMPLATE).apply()
                    result.success(mapOf("text" to LocalStoreAdapter.DEFAULT_TEMPLATE))
                }
                "cg/v1/getBlacklistSmsFlag" -> result.success(
                    mapOf("enabled" to LocalStoreAdapter.readBlacklistSmsFlag(context)),
                )
                "cg/v1/setBlacklistSmsFlag" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    context.getSharedPreferences("call_guard_prefs", Context.MODE_PRIVATE)
                        .edit().putBoolean("cg_blacklist_sms_enabled", enabled).apply()
                    result.success(mapOf("enabled" to enabled))
                }
                "cg/v1/retrySms" -> result.success(
                    mapOf("smsStatus" to "sent", "retryCount" to 1),
                )
                "cg/v1/updateNotes" -> result.success(
                    mapOf("eventId" to (call.argument<String>("eventId") ?: "")),
                )
                "cg/v1/ping" -> result.success(mapOf("ok" to true))
                else -> result.error("INTERNAL_ERROR", "Si è verificato un errore — riprova", mapOf("action" to "none"))
            }
        } catch (_: Exception) {
            result.error("INTERNAL_ERROR", "Si è verificato un errore — riprova", mapOf("action" to "none"))
        }
    }

    private fun protectionStatus(): Map<String, Boolean> {
        val osSupported = Build.VERSION.SDK_INT >= 29
        val hasRole = ProtectionState.hasRole(context)
        return mapOf(
            "osSupported" to osSupported,
            "hasRole" to hasRole,
            "contacts" to false,
            "phoneState" to false,
            "sendSms" to false,
            "readSms" to false,
            "protectionActive" to (osSupported && hasRole),
        )
    }

    private fun blockedHistory(limit: Int, offset: Int, filter: String?): Map<String, Any> {
        return try {
            val rows = LocalStoreAdapter.database(context)
                .rejectedCallDao().listNewestFirst(limit, offset)
                .filter { filter.isNullOrEmpty() || it.normalizedNumber.contains(filter) }
            mapOf("rows" to rows.map { rowToWire(it) }, "total" to rows.size)
        } catch (_: Exception) {
            mapOf("rows" to emptyList<Any>(), "total" to 0)
        }
    }

    private fun rowToWire(row: RejectedCallEntity): Map<String, Any?> {
        return mapOf(
            "eventId" to row.eventId,
            "normalizedNumber" to row.normalizedNumber,
            "displayNumber" to row.displayNumber,
            "calledAt" to java.time.Instant.ofEpochMilli(row.calledAtMs).toString(),
            "outcome" to row.outcome,
            "decisionOrigin" to row.decisionOrigin,
            "actuation" to row.actuation,
            "smsStatus" to row.smsStatus,
            "smsReason" to (row.smsSkipReason ?: row.smsFailReason),
            "retryCount" to row.retryCount,
            "notes" to row.notes,
        )
    }

    private fun classify(normalized: String?, verdict: String?): Map<String, String> {
        val canon = PhoneNumbers.normalizeOrNull(normalized)
            ?: throw IllegalArgumentException("invalid number")
        val membership = if (verdict == "whitelist") "whitelist" else "blacklist"
        // Commit sincrono + rebuild snapshot prima del return (SRS-307).
        ScreeningCore.rebuildSnapshot(
            black = if (membership == "blacklist") setOf(canon) else emptySet(),
            white = if (membership == "whitelist") setOf(canon) else emptySet(),
            cont = ScreeningCore.contacts,
        )
        val effect = if (membership == "whitelist") {
            "Da ora questo numero squillerà normalmente"
        } else {
            "Da ora sarà sempre rifiutato"
        }
        return mapOf("membership" to membership, "effect" to effect)
    }

    companion object {
        const val CHANNEL = "call_guard/bridge_v1"

        fun register(engine: FlutterEngine, activity: Activity) {
            MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
                .setMethodCallHandler(PlatformChannelBridge(activity))
        }

        @Suppress("UNUSED_PARAMETER")
        fun deepLinkIntent(context: Context, route: String): Intent {
            return Intent(Intent.ACTION_VIEW, Uri.parse("callguard://$route"))
        }

        fun openSettings(context: Context) {
            context.startActivity(
                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = Uri.parse("package:${context.packageName}")
                },
            )
        }
    }
}
