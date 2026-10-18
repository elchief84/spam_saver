package it.spamsaver

import android.content.Context
import it.spamsaver.dominio.TETTO_GIORNALIERO_PREDEFINITO

/**
 * Le preferenze dell'app, tutte sul telefono (ADR-0003): il testo dell'SMS di
 * identificazione e il tetto giornaliero degli invii. Il testo predefinito è
 * quello delle risorse; il tetto predefinito è quello del dominio.
 */
class Impostazioni(context: Context) {

    private val preferenze = context.getSharedPreferences(NOME, Context.MODE_PRIVATE)
    private val testoPredefinito = context.getString(R.string.sms_identificazione_predefinito)

    /** Il testo che parte dopo un rifiuto: quello scelto dall'utente o il predefinito. */
    var testoSms: String
        get() = preferenze.getString(CHIAVE_TESTO, null)?.takeIf { it.isNotBlank() } ?: testoPredefinito
        set(valore) {
            preferenze.edit().putString(CHIAVE_TESTO, valore).apply()
        }

    /** Quanti SMS di identificazione possono partire in un giorno. */
    var tettoGiornaliero: Int
        get() = preferenze.getInt(CHIAVE_TETTO, TETTO_GIORNALIERO_PREDEFINITO).coerceAtLeast(1)
        set(valore) {
            preferenze.edit().putInt(CHIAVE_TETTO, valore.coerceAtLeast(1)).apply()
        }

    /**
     * Quando l'app ha respinto senza scrivere perché il tetto era raggiunto:
     * serve a dirlo anche a chi apre l'app senza aver visto la notifica.
     */
    var ultimoTettoRaggiunto: Long
        get() = preferenze.getLong(CHIAVE_TETTO_RAGGIUNTO, 0L)
        set(valore) {
            preferenze.edit().putLong(CHIAVE_TETTO_RAGGIUNTO, valore).apply()
        }

    private companion object {
        const val NOME = "spam_saver"
        const val CHIAVE_TESTO = "testo_sms_identificazione"
        const val CHIAVE_TETTO = "tetto_giornaliero"
        const val CHIAVE_TETTO_RAGGIUNTO = "ultimo_tetto_raggiunto"
    }
}
