package it.spamsaver

import android.content.Context
import it.spamsaver.dominio.Chiamata
import it.spamsaver.dominio.EsitoChiamata
import it.spamsaver.dominio.NumeroTelefono
import it.spamsaver.dominio.Respinto
import it.spamsaver.dominio.StoricoRespinti
import java.io.File
import java.time.Instant

/**
 * Lo storico dei respinti, scritto nel magazzino privato dell'app: una riga per
 * respinta — il momento in millisecondi e il numero canonico, separati da tab.
 *
 * Tutto locale: nessun backend, nessuna sincronizzazione (ADR-0003). La regola
 * «ogni respinta è registrata» è quella pura di [StoricoRespinti]; qui c'è solo
 * il file.
 */
class ArchivioRespinti(context: Context) {

    private val file = File(context.filesDir, RESPINTI)

    /** Le respinte finora, in ordine di arrivo. */
    @Synchronized
    fun leggi(): StoricoRespinti = StoricoRespinti(
        file.takeIf { it.isFile }?.readLines().orEmpty().mapNotNull(::daRiga),
    )

    /**
     * Registra la respinta se la chiamata non passa; una chiamata che passa
     * lascia il file com'è.
     */
    @Synchronized
    fun registra(chiamata: Chiamata, esito: EsitoChiamata, quando: Instant) {
        val storico = leggi()
        val aggiornato = storico.registra(chiamata, esito, quando)
        if (aggiornato === storico) return

        file.parentFile?.mkdirs()
        file.appendText(inRiga(aggiornato.elenco.last()) + "\n")
    }

    private fun inRiga(respinto: Respinto): String =
        "${respinto.quando.toEpochMilli()}\t${respinto.numero}"

    private fun daRiga(riga: String): Respinto? {
        val parti = riga.split('\t')
        if (parti.size != 2) return null
        val quando = parti[0].toLongOrNull() ?: return null
        val numero = NumeroTelefono.da(parti[1]) ?: return null
        return Respinto(numero, Instant.ofEpochMilli(quando))
    }

    private companion object {
        const val RESPINTI = "respinti.tsv"
    }
}
