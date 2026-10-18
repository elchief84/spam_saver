package it.spamsaver

import android.content.Context
import it.spamsaver.dominio.ConversazioniArchiviate
import it.spamsaver.dominio.NumeroTelefono
import java.io.File

/**
 * Le conversazioni archiviate, nel magazzino privato: un numero canonico per
 * riga. Archiviare una conversazione la toglie dall'elenco principale; i
 * messaggi restano in [ArchivioMessaggi], così il ripristino li ritrova.
 */
class ArchivioConversazioni(context: Context) {

    private val file = File(context.filesDir, ARCHIVIATE)

    /** Le conversazioni archiviate. */
    @Synchronized
    fun leggi(): ConversazioniArchiviate = ConversazioniArchiviate(
        file.takeIf { it.isFile }
            ?.readLines()
            .orEmpty()
            .mapNotNull(NumeroTelefono::da)
            .toSet(),
    )

    /** Archivia la conversazione con [numero]. */
    @Synchronized
    fun archivia(numero: NumeroTelefono) {
        val archiviate = leggi()
        if (archiviate.contiene(numero)) return
        scrivi(archiviate.archivia(numero))
    }

    /** Ripristina la conversazione con [numero]. */
    @Synchronized
    fun ripristina(numero: NumeroTelefono) {
        val archiviate = leggi()
        if (!archiviate.contiene(numero)) return
        scrivi(archiviate.ripristina(numero))
    }

    private fun scrivi(archiviate: ConversazioniArchiviate) {
        file.parentFile?.mkdirs()
        file.writeText(archiviate.numeri.joinToString("\n") { it.canonico })
    }

    private companion object {
        const val ARCHIVIATE = "conversazioni-archiviate.txt"
    }
}
