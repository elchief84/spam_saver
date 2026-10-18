package it.spamsaver

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Il ricevitore degli MMS, che Spam Saver lascia fuori perimetro (ADR-0005):
 * un MMS in arrivo non si vede, ma non fa cadere l'app e non nasconde gli
 * altri messaggi. Ignorarlo qui è tutto quello che serve.
 */
class MmsReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        // Un MMS non è un SMS: niente download, niente thread, niente crash.
    }
}
