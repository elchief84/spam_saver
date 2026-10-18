package it.spamsaver

import android.content.Context
import it.spamsaver.dominio.Bloccati
import it.spamsaver.dominio.NumeroTelefono
import java.io.File

/**
 * I mittenti bloccati, nel magazzino privato: un numero canonico per riga.
 * Bloccare un mittente non cambia il trattamento delle sue chiamate — respingere
 * gli sconosciuti è già il comportamento predefinito: i suoi SMS restano nella
 * conversazione, ma non si notificano.
 */
class ArchivioBloccati(context: Context) {

    private val file = File(context.filesDir, BLOCCATI)

    /** I mittenti bloccati. */
    @Synchronized
    fun leggi(): Bloccati = Bloccati(
        file.takeIf { it.isFile }
            ?.readLines()
            .orEmpty()
            .mapNotNull(NumeroTelefono::da)
            .toSet(),
    )

    /** Blocca [numero]. */
    @Synchronized
    fun blocca(numero: NumeroTelefono) {
        val bloccati = leggi()
        if (bloccati.contiene(numero)) return
        scrivi(bloccati.blocca(numero))
    }

    /** Sblocca [numero]. */
    @Synchronized
    fun sblocca(numero: NumeroTelefono) {
        val bloccati = leggi()
        if (!bloccati.contiene(numero)) return
        scrivi(bloccati.sblocca(numero))
    }

    private fun scrivi(bloccati: Bloccati) {
        file.parentFile?.mkdirs()
        file.writeText(bloccati.numeri.joinToString("\n") { it.canonico })
    }

    private companion object {
        const val BLOCCATI = "bloccati.txt"
    }
}
