package it.spamsaver

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import it.spamsaver.dominio.NumeroTelefono
import java.time.Instant

/**
 * Riceve gli SMS quando Spam Saver è il gestore predefinito (`SMS_DELIVER`):
 * li registra nel magazzino locale e li notifica. Da qui l'utente li legge e
 * risponde dentro l'app.
 *
 * Qui si gestiscono solo gli SMS: gli MMS hanno il loro ricevitore, che li
 * lascia fuori perimetro (ADR-0005).
 */
class SmsReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Telephony.Sms.Intents.SMS_DELIVER_ACTION) return

        val messaggi = try {
            Telephony.Sms.Intents.getMessagesFromIntent(intent).orEmpty()
        } catch (_: Exception) {
            // Un intent malformato non deve far cadere l'app.
            return
        }

        val archivio = ArchivioMessaggi(context)
        val notifiche = Notifiche(context)
        messaggi
            .groupBy { it.displayOriginatingAddress ?: it.originatingAddress }
            .forEach { (indirizzo, parti) ->
                val numero = NumeroTelefono.da(indirizzo ?: return@forEach) ?: return@forEach
                val testo = parti.joinToString(separator = "") { it.displayMessageBody.orEmpty() }
                if (testo.isBlank()) return@forEach

                val messaggio = Messaggio(numero, testo, Instant.now(), inviato = false)
                archivio.registra(messaggio)
                notifiche.messaggioRicevuto(messaggio)
            }
    }
}
