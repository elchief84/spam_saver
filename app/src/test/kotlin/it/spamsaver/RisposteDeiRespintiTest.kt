package it.spamsaver

import it.spamsaver.dominio.Messaggio
import it.spamsaver.dominio.NumeroTelefono
import it.spamsaver.dominio.Respinto
import java.time.Instant
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class RisposteDeiRespintiTest {

    private fun numero(canonico: String): NumeroTelefono =
        requireNotNull(NumeroTelefono.da(canonico)) { "numero di test non valido: $canonico" }

    private val inizio = Instant.parse("2026-10-18T09:30:00Z")

    private fun respinto(canonico: String, minuto: Long = 0) =
        Respinto(numero(canonico), inizio.plusSeconds(minuto * 60))

    private fun ricevuto(canonico: String, testo: String, minuto: Long = 0) =
        Messaggio(numero(canonico), testo, inizio.plusSeconds(minuto * 60), inviato = false)

    private fun inviato(canonico: String, testo: String, minuto: Long = 0) =
        Messaggio(numero(canonico), testo, inizio.plusSeconds(minuto * 60), inviato = true)

    @Test
    fun `un numero respinto che ha risposto mostra la sua risposta`() {
        val risposte = risposteDeiRespinti(
            respinti = listOf(respinto("3331234567")),
            messaggi = listOf(ricevuto("3331234567", "Sono il tecnico")),
        )

        assertEquals("Sono il tecnico", risposte[numero("3331234567")]?.testo)
    }

    @Test
    fun `l'SMS di identificazione mandato da noi non è una risposta`() {
        val risposte = risposteDeiRespinti(
            respinti = listOf(respinto("3331234567")),
            messaggi = listOf(inviato("3331234567", "Chi sei?")),
        )

        assertTrue(risposte.isEmpty())
    }

    @Test
    fun `una respinta senza risposta non compare nel riepilogo`() {
        val risposte = risposteDeiRespinti(
            respinti = listOf(respinto("3331234567"), respinto("0612345678")),
            messaggi = listOf(ricevuto("0612345678", "Sono il corriere")),
        )

        assertEquals(setOf(numero("0612345678")), risposte.keys)
    }

    @Test
    fun `con più risposte si mostra l'ultima`() {
        val risposte = risposteDeiRespinti(
            respinti = listOf(respinto("3331234567")),
            messaggi = listOf(
                ricevuto("3331234567", "Prima", minuto = 0),
                ricevuto("3331234567", "Ultima", minuto = 5),
            ),
        )

        assertEquals("Ultima", risposte[numero("3331234567")]?.testo)
    }

    @Test
    fun `lo stesso numero respinto più volte mostra una sola risposta`() {
        val risposte = risposteDeiRespinti(
            respinti = listOf(respinto("3331234567"), respinto("3331234567", minuto = 1)),
            messaggi = listOf(ricevuto("3331234567", "Sono io")),
        )

        assertEquals(1, risposte.size)
        assertEquals("Sono io", risposte[numero("3331234567")]?.testo)
    }
}
