package it.spamsaver

import android.app.Service
import android.content.Intent
import android.os.IBinder
import it.spamsaver.dominio.Messaggio
import it.spamsaver.dominio.NumeroTelefono
import java.time.Instant

/**
 * La risposta rapida da fuori l'app (`RESPOND_VIA_MESSAGE`): Android la offre
 * al gestore SMS predefinito. Manda il testo e lo registra nella conversazione,
 * così la risposta si ritrova anche dentro Spam Saver.
 */
class RispostaRapidaService : Service() {

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val numero = intent?.data?.schemeSpecificPart?.let(NumeroTelefono::da)
        val testo = intent?.getStringExtra(Intent.EXTRA_TEXT)
        if (numero != null && !testo.isNullOrBlank() && InvioSms(this).manda(numero, testo)) {
            ArchivioMessaggi(this).registra(
                Messaggio(numero, testo, Instant.now(), inviato = true),
            )
        }
        stopSelf(startId)
        return START_NOT_STICKY
    }
}
