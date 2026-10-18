package it.spamsaver

import android.content.Context
import it.spamsaver.dominio.Messaggio
import it.spamsaver.dominio.NumeroTelefono
import it.spamsaver.dominio.Respinto
import java.io.File
import java.time.Instant
import java.util.Base64

/**
 * Le conversazioni lette e scritte dentro Spam Saver, nel magazzino privato
 * dell'app. Il testo è codificato in Base64 per stare su una riga sola: la
 * messaggistica non è un formato a colonne.
 *
 * Tutto locale: nessun backend, nessuna sincronizzazione (ADR-0003). Il modello
 * e le regole sui messaggi vivono nel dominio; qui c'è solo il file.
 */
class ArchivioMessaggi(context: Context) {

    private val file = File(context.filesDir, MESSAGGI)

    /** Tutti i messaggi, in ordine di arrivo. */
    @Synchronized
    fun leggi(): List<Messaggio> =
        file.takeIf { it.isFile }?.readLines().orEmpty().mapNotNull(::daRiga)

    /** Registra un messaggio ricevuto o inviato. */
    @Synchronized
    fun registra(messaggio: Messaggio) {
        file.parentFile?.mkdirs()
        file.appendText(inRiga(messaggio) + "\n")
    }

    private fun inRiga(messaggio: Messaggio): String {
        val direzione = if (messaggio.inviato) INVIATO else RICEVUTO
        val testo = Base64.getEncoder().encodeToString(messaggio.testo.toByteArray(Charsets.UTF_8))
        return "${messaggio.quando.toEpochMilli()}\t$direzione\t${messaggio.numero.canonico}\t$testo"
    }

    private fun daRiga(riga: String): Messaggio? {
        val parti = riga.split('\t')
        if (parti.size != 4) return null
        val quando = parti[0].toLongOrNull() ?: return null
        val inviato = parti[1] == INVIATO
        val numero = NumeroTelefono.da(parti[2]) ?: return null
        val testo = try {
            String(Base64.getDecoder().decode(parti[3]), Charsets.UTF_8)
        } catch (_: IllegalArgumentException) {
            return null
        }
        return Messaggio(numero, testo, Instant.ofEpochMilli(quando), inviato)
    }

    private companion object {
        const val MESSAGGI = "messaggi.tsv"
        const val RICEVUTO = "I"
        const val INVIATO = "U"
    }
}

/**
 * L'ultima **risposta** ricevuta da ciascun numero respinto, indicizzata per
 * numero: le respinte senza risposta non compaiono.
 *
 * Una risposta è un messaggio ricevuto: l'SMS di identificazione che abbiamo
 * mandato noi non conta. È quello che il riepilogo dei respinti mostra accanto
 * al numero che ha risposto.
 */
fun risposteDeiRespinti(
    respinti: List<Respinto>,
    messaggi: List<Messaggio>,
): Map<NumeroTelefono, Messaggio> {
    val ricevutePerNumero = messaggi.filter { !it.inviato }.groupBy { it.numero }
    return respinti.map { it.numero }
        .distinct()
        .mapNotNull { numero ->
            ricevutePerNumero[numero]?.maxByOrNull { it.quando }?.let { numero to it }
        }
        .toMap()
}
