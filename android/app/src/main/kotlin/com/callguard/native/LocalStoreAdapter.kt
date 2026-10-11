package com.callguard.native

import android.content.Context
import androidx.room.Dao
import androidx.room.Database
import androidx.room.Entity
import androidx.room.Insert
import androidx.room.PrimaryKey
import androidx.room.Query
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.Transaction
import java.util.UUID

@Entity(tableName = "rejected_calls")
data class RejectedCallEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val eventId: String = UUID.randomUUID().toString(),
    val normalizedNumber: String = "",
    val displayNumber: String = "",
    val calledAtMs: Long = 0,
    val outcome: String = "rejected",
    val decisionOrigin: String = "unknown",
    val actuation: String = "disconnect",
    val smsStatus: String = "pending",
    val smsSkipReason: String? = null,
    val smsFailReason: String? = null,
    val templateRef: String? = null,
    val retryCount: Int = 0,
    val notes: String = "",
)

@Entity(tableName = "trusted_entries")
data class TrustedEntryEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val normalizedNumber: String = "",
    val displayNumber: String = "",
    val list: String = "whitelist",
    val displayName: String = "",
    val notes: String = "",
    val category: String = "",
    val source: String = "manual",
    val dateAddedMs: Long = 0,
    val lastModifiedMs: Long = 0,
)

@Dao
interface RejectedCallDao {
    @Insert
    fun insert(row: RejectedCallEntity): Long

    @Query("SELECT * FROM rejected_calls ORDER BY calledAtMs DESC LIMIT :limit OFFSET :offset")
    fun listNewestFirst(limit: Int, offset: Int): List<RejectedCallEntity>

    @Query("SELECT * FROM rejected_calls WHERE eventId = :eventId LIMIT 1")
    fun byEventId(eventId: String): RejectedCallEntity?
}

@Database(
    entities = [RejectedCallEntity::class, TrustedEntryEntity::class],
    version = 1,
    exportSchema = true,
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun rejectedCallDao(): RejectedCallDao
}

/**
 * SU-INF-05-01 — Room v1 + prefs + rebuild snapshot sincrono nella
 * stessa transazione (SRS-307). allowBackup=false, no provider esportato.
 */
object LocalStoreAdapter {
    const val DEFAULT_TEMPLATE =
        "La chiamata è stata automaticamente rifiutata dal ricevente " +
            "perché il suo numero è sconosciuto, le preghiamo di inviare " +
            "un sms con le informazioni necessarie alla sua identificazione."

    @Volatile private var db: AppDatabase? = null

    fun database(context: Context): AppDatabase {
        return db ?: synchronized(this) {
            db ?: Room.databaseBuilder(
                context.applicationContext,
                AppDatabase::class.java,
                "call_guard.db",
            ).build().also { db = it }
        }
    }

    @Transaction
    fun insertRejectedCall(context: Context, verdict: ScreeningVerdict, raw: String?) {
        val normalized = PhoneNumbers.normalizeOrNull(raw) ?: return
        database(context).rejectedCallDao().insert(
            RejectedCallEntity(
                normalizedNumber = normalized,
                displayNumber = raw ?: normalized,
                calledAtMs = System.currentTimeMillis(),
                decisionOrigin = verdict.origin,
                actuation = "disconnect",
            ),
        )
    }

    fun readTemplate(context: Context): String {
        val prefs = context.getSharedPreferences("call_guard_prefs", Context.MODE_PRIVATE)
        val existing = prefs.getString("cg_sms_template_text", null)
        if (existing != null) return existing
        prefs.edit().putString("cg_sms_template_text", DEFAULT_TEMPLATE).apply()
        return DEFAULT_TEMPLATE
    }

    fun readBlacklistSmsFlag(context: Context): Boolean {
        val prefs = context.getSharedPreferences("call_guard_prefs", Context.MODE_PRIVATE)
        return prefs.getBoolean("cg_blacklist_sms_enabled", false)
    }
}
