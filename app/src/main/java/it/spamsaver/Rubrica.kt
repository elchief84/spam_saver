package it.spamsaver

import android.content.Context
import android.net.Uri
import android.provider.ContactsContract
import it.spamsaver.dominio.Chiamata
import it.spamsaver.dominio.NumeroTelefono
import it.spamsaver.dominio.StatoTelefono

/**
 * La rubrica del telefono, letta per decidere se un numero è conosciuto.
 *
 * Un numero in rubrica passa sempre senza chiedere niente a nessuno
 * (CONTEXT.md): lo stato che ne esce è esattamente «questo numero è in rubrica».
 * Senza il permesso di lettura la rubrica risulta vuota e i numeri passano come
 * sconosciuti — è il motivo per cui l'onboarding lo chiede.
 */
class Rubrica(private val context: Context) {

    /** Lo stato del telefono per [chiamata]: per ora solo la rubrica. */
    fun statoPer(chiamata: Chiamata): StatoTelefono = when (chiamata) {
        is Chiamata.Numero ->
            StatoTelefono(
                inRubrica = if (conosce(chiamata.numero)) setOf(chiamata.numero) else emptySet(),
            )

        Chiamata.Nascosta,
        Chiamata.NonInterpretabile,
        -> StatoTelefono()
    }

    private fun conosce(numero: NumeroTelefono): Boolean {
        val uri = Uri.withAppendedPath(
            ContactsContract.PhoneLookup.CONTENT_FILTER_URI,
            Uri.encode(numero.canonico),
        )
        val colonne = arrayOf(ContactsContract.PhoneLookup._ID)
        return context.contentResolver
            .query(uri, colonne, null, null, null)
            ?.use { it.moveToFirst() }
            ?: false
    }
}
