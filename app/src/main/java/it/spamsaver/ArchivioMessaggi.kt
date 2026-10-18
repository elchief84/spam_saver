package it.spamsaver

import android.content.Context
import it.spamsaver.dominio.NumeroTelefono
import java.io.File
import java.time.Instant
import java.util.Base64

/** Un messaggio scambiato con [numero]: ricevuto o inviato da Spam Saver. */
data class Messaggio(
    val numero: NumeroTelefono,
    val testo: String,
    val quando: Instant,
    val inviato: Boolean,
)

/** I messaggi di un numero, in ordine di arrivo. */
data class Conversazione(val numero: NumeroTelefono, val messaggi: List<Messaggio>)

/**
 * Le conversazioni lette e scritte dentro Spam Saver, nel magazzino privato
 * dell'app. Il testo è codificato in Base64 per stare su una riga sola: la
 * messaggistica non è un formato a colonne.
 *
 * Tutto locale: nessun backend, nessuna sincronizzazione (ADR-0003).
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

/** Raggruppa i messaggi per numero, i più recenti per primi. */
fun conversazioniDi(messaggi: List<Messaggio>): List<Conversazione> =
    messaggi.groupBy { it.numero }
        .map { (numero, elenco) -> Conversazione(numero, elenco.sortedBy { it.quando }) }
        .sortedByDescending { it.messaggi.last().quando }
