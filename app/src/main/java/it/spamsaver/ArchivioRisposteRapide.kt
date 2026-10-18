package it.spamsaver

import android.content.Context
import it.spamsaver.dominio.RisposteRapide
import java.io.File

/**
 * Le risposte rapide configurate dall'utente, nel magazzino privato: un testo
 * per riga. Si usano da una conversazione per rispondere senza riscriverle.
 */
class ArchivioRisposteRapide(context: Context) {

    private val file = File(context.filesDir, RISPOSTE)

    /** Le risposte rapide configurate. */
    @Synchronized
    fun leggi(): RisposteRapide = RisposteRapide(
        file.takeIf { it.isFile }
            ?.readLines()
            .orEmpty()
            .map { it.trim() }
            .filter { it.isNotEmpty() },
    )

    /** Aggiunge [testo] alle risposte rapide. */
    @Synchronized
    fun aggiungi(testo: String) {
        val risposte = leggi()
        val aggiornate = risposte.aggiungi(testo)
        if (aggiornate === risposte) return
        scrivi(aggiornate)
    }

    /** Toglie [testo] dalle risposte rapide. */
    @Synchronized
    fun rimuovi(testo: String) {
        val risposte = leggi()
        val aggiornate = risposte.rimuovi(testo)
        if (aggiornate === risposte) return
        scrivi(aggiornate)
    }

    private fun scrivi(risposte: RisposteRapide) {
        file.parentFile?.mkdirs()
        file.writeText(risposte.elenco.joinToString("\n"))
    }

    private companion object {
        const val RISPOSTE = "risposte-rapide.txt"
    }
}
