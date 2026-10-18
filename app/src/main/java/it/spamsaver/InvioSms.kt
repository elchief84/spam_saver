package it.spamsaver

import android.Manifest
import android.app.role.RoleManager
import android.content.Context
import android.content.pm.PackageManager
import android.telephony.SmsManager
import androidx.core.content.ContextCompat
import it.spamsaver.dominio.NumeroTelefono

/**
 * L'invio di SMS dal lato del telefono. L'SMS di identificazione e le risposte
 * dell'utente passano entrambi di qui.
 *
 * Si può mandare solo se l'app tiene il ruolo di **gestore SMS predefinito** e
 * ha il permesso `SEND_SMS`: senza, non parte niente e [manda] restituisce
 * `false`, così l'interrogato non viene segnato per sbaglio.
 */
class InvioSms(private val context: Context) {

    /** `true` se ci sono sia il ruolo sia il permesso per mandare SMS. */
    fun puoInviare(): Boolean = haRuolo() && haPermesso()

    /**
     * Manda [testo] a [numero]. Restituisce `true` se l'invio è stato affidato
     * al telefono; `false` se manca ruolo, permesso o se inviare fallisce.
     */
    @Suppress("DEPRECATION")
    fun manda(numero: NumeroTelefono, testo: String): Boolean {
        if (!puoInviare()) return false

        return try {
            val gestore = SmsManager.getDefault()
            val parti = gestore.divideMessage(testo)
            if (parti.size <= 1) {
                gestore.sendTextMessage(numero.canonico, null, testo, null, null)
            } else {
                gestore.sendMultipartTextMessage(numero.canonico, null, parti, null, null)
            }
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun haRuolo(): Boolean {
        val gestoreRuoli = context.getSystemService(RoleManager::class.java) ?: return false
        return gestoreRuoli.isRoleHeld(RoleManager.ROLE_SMS)
    }

    private fun haPermesso(): Boolean =
        ContextCompat.checkSelfPermission(context, Manifest.permission.SEND_SMS) ==
            PackageManager.PERMISSION_GRANTED
}
