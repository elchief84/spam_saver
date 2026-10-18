package it.spamsaver

import android.content.Context
import it.spamsaver.dominio.NumeroTelefono
import java.io.File

/**
 * La memoria degli **interrogati**: i numeri a cui l'SMS di identificazione è
 * già partito. Vive in un file privato dell'app, quindi sopravvive al riavvio e
 * impedisce il secondo SMS anche quando il numero richiama (ADR-0002).
 */
class ArchivioInterrogati(context: Context) {

    private val file = File(context.filesDir, INTERROGATI)

    /** `true` se a [numero] è già stato mandato l'SMS di identificazione. */
    @Synchronized
    fun giaInterrogato(numero: NumeroTelefono): Boolean = numero.canonico in leggi()

    /** Segna [numero] come interrogato: da qui in poi non riceverà altri SMS. */
    @Synchronized
    fun segnaInterrogato(numero: NumeroTelefono) {
        if (numero.canonico in leggi()) return

        file.parentFile?.mkdirs()
        file.appendText(numero.canonico + "\n")
    }

    private fun leggi(): Set<String> =
        file.takeIf { it.isFile }?.readLines()?.map { it.trim() }?.filter { it.isNotEmpty() }?.toSet()
            ?: emptySet()

    private companion object {
        const val INTERROGATI = "interrogati.tsv"
    }
}
