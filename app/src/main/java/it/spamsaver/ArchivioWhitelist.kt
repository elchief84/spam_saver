package it.spamsaver

import android.content.Context
import it.spamsaver.dominio.NumeroTelefono
import java.io.File

/**
 * La whitelist dell'app, scritta nel magazzino privato: un numero canonico per
 * riga.
 *
 * La scrittura è locale e senza sincronizzazione (ADR-0003). I numeri si
 * confrontano sempre in forma canonica, così prefissi e separatori non contano
 * (storia utente 26); la normalizzazione è quella di [NumeroTelefono].
 */
class ArchivioWhitelist(context: Context) {

    private val file = File(context.filesDir, WHITELIST)

    /** I numeri in whitelist, senza duplicati. */
    @Synchronized
    fun leggi(): Set<NumeroTelefono> =
        file.takeIf { it.isFile }
            ?.readLines()
            .orEmpty()
            .mapNotNull(NumeroTelefono::da)
            .toSet()

    /** Aggiunge [numero] alla whitelist; se c'è già non cambia niente. */
    @Synchronized
    fun aggiungi(numero: NumeroTelefono) {
        val numeri = leggi()
        if (numero in numeri) return

        file.parentFile?.mkdirs()
        file.appendText("$numero\n")
    }

    /** Toglie [numero] dalla whitelist; se non c'è non cambia niente. */
    @Synchronized
    fun rimuovi(numero: NumeroTelefono) {
        val numeri = leggi()
        if (numero !in numeri) return

        file.writeText((numeri - numero).joinToString("\n") { it.canonico })
    }

    private companion object {
        const val WHITELIST = "whitelist.txt"
    }
}
