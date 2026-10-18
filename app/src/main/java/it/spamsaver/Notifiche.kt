package it.spamsaver

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.content.ContextCompat

/**
 * Le notifiche dell'app: un SMS in arrivo e l'avviso che il tetto giornaliero
 * ha fermato gli invii. Senza il permesso di notifica si tace: il messaggio
 * resta comunque nell'elenco, e il tetto resta scritto nelle preferenze.
 */
class Notifiche(private val context: Context) {

    /** Notifica l'SMS appena arrivato da [messaggio]. */
    fun messaggioRicevuto(messaggio: Messaggio) {
        if (!puoNotificare()) return

        val notifica = base(CANALE_MESSAGGI)
            .setContentTitle(messaggio.numero.canonico)
            .setContentText(messaggio.testo)
            .setStyle(Notification.BigTextStyle().bigText(messaggio.testo))
            .build()
        gestore().notify(messaggio.numero.hashCode(), notifica)
    }

    /**
     * Avvisa che il tetto giornaliero è stato raggiunto: la chiamata è stata
     * respinta, ma nessun SMS è partito.
     */
    fun tettoRaggiunto() {
        if (!puoNotificare()) return

        val notifica = base(CANALE_AVVISI)
            .setContentTitle(context.getString(R.string.notifica_tetto_titolo))
            .setContentText(context.getString(R.string.notifica_tetto_testo))
            .setStyle(
                Notification.BigTextStyle()
                    .bigText(context.getString(R.string.notifica_tetto_testo)),
            )
            .build()
        gestore().notify(ID_TETTO, notifica)
    }

    private fun base(canale: String): Notification.Builder {
        creaCanale(canale)
        return Notification.Builder(context, canale)
            .setSmallIcon(android.R.drawable.ic_dialog_email)
            .setAutoCancel(true)
            .setContentIntent(apriApp())
    }

    private fun apriApp(): PendingIntent {
        val intent = Intent(context, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        return PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun creaCanale(canale: String) {
        val nome = when (canale) {
            CANALE_AVVISI -> context.getString(R.string.notifica_canale_avvisi)
            else -> context.getString(R.string.notifica_canale_messaggi)
        }
        val gestore = context.getSystemService(NotificationManager::class.java) ?: return
        gestore.createNotificationChannel(
            NotificationChannel(canale, nome, NotificationManager.IMPORTANCE_DEFAULT),
        )
    }

    private fun gestore(): NotificationManager =
        requireNotNull(context.getSystemService(NotificationManager::class.java))

    private fun puoNotificare(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED

    private companion object {
        const val CANALE_MESSAGGI = "messaggi"
        const val CANALE_AVVISI = "avvisi"
        const val ID_TETTO = 1
    }
}
