package it.spamsaver

import android.content.Context
import java.io.File
import java.time.LocalDate

/**
 * Il conto degli SMS di identificazione partiti oggi. Vive in un file privato
 * dell'app, così il tetto non riparte da zero a ogni riavvio.
 */
class RegistroInvii(context: Context) {

    private val file = File(context.filesDir, INVII)

    /** Quanti SMS di identificazione sono partiti nel giorno [oggi]. */
    @Synchronized
    fun inviatiOggi(oggi: LocalDate): Int {
        val riga = leggi() ?: return 0
        return if (riga.giorno == oggi.toEpochDay()) riga.quantita else 0
    }

    /** Registra un invio nel giorno [oggi]. */
    @Synchronized
    fun registra(oggi: LocalDate) {
        val quantita = inviatiOggi(oggi) + 1
        file.parentFile?.mkdirs()
        file.writeText("${oggi.toEpochDay()}\t$quantita\n")
    }

    private fun leggi(): Riga? {
        val parti = file.takeIf { it.isFile }?.readText()?.trim()?.split('\t') ?: return null
        if (parti.size != 2) return null
        val giorno = parti[0].toLongOrNull() ?: return null
        val quantita = parti[1].toIntOrNull() ?: return null
        return Riga(giorno, quantita)
    }

    private data class Riga(val giorno: Long, val quantita: Int)

    private companion object {
        const val INVII = "invii.tsv"
    }
}
