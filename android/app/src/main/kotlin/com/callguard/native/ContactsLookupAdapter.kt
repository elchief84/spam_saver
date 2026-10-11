package com.callguard.native

import android.content.Context
import android.net.Uri
import android.provider.ContactsContract

/**
 * SU-INF-02-01 — presence check sola lettura + snapshot builder.
 * Mai copia contatti: solo booleano presenza. Negato -> false per tutti
 * + guidance PERMISSION_DENIED_CONTACTS (SRS-203).
 */
object ContactsLookupAdapter {
    fun isInContacts(context: Context, normalized: String): Boolean {
        return try {
            val uri: Uri = Uri.withAppendedPath(
                ContactsContract.PhoneLookup.CONTENT_FILTER_URI,
                Uri.encode(normalized),
            )
            context.contentResolver.query(
                uri,
                arrayOf(ContactsContract.PhoneLookup._ID),
                null, null, null,
            )?.use { c -> c.count > 0 } ?: false
        } catch (_: Exception) {
            false
        }
    }
}
