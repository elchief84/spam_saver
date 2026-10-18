package it.spamsaver.dominio

import java.time.Instant
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class RicercaTest {

    private fun numero(canonico: String): NumeroTelefono =
        requireNotNull(NumeroTelefono.da(canonico)) { "numero di test non valido: $canonico" }

    private fun messaggio(
        numero: NumeroTelefono,
        testo: String,
        istante: String,
        inviato: Boolean = false,
    ): Messaggio = Messaggio(numero, testo, Instant.parse(istante), inviato)

    private val luca = numero("3331234567")
    private val anna = numero("0612345678")

    private val conversazioni = listOf(
        Conversazione(
            luca,
            listOf(
                messaggio(luca, "Ciao, chi sei?", "2026-10-18T09:00:00Z"),
                messaggio(luca, "Sono il corriere", "2026-10-18T09:01:00Z", inviato = true),
            ),
        ),
        Conversazione(
            anna,
            listOf(messaggio(anna, "Buongiorno", "2026-10-18T09:02:00Z")),
        ),
    )

    @Test
    fun `la ricerca trova la conversazione e i messaggi che contengono il testo`() {
        val trovati = cerca(conversazioni, "chi sei")

        assertEquals(1, trovati.size)
        assertEquals(luca, trovati.single().conversazione.numero)
        assertEquals(listOf("Ciao, chi sei?"), trovati.single().messaggi.map { it.testo })
    }

    @Test
    fun `piu messaggi della stessa conversazione possono contenere il testo`() {
        val conversazione = Conversazione(
            luca,
            listOf(
                messaggio(luca, "premio", "2026-10-18T09:00:00Z"),
                messaggio(luca, "premio vinto", "2026-10-18T09:01:00Z"),
            ),
        )

        val trovati = cerca(listOf(conversazione), "premio")

        assertEquals(2, trovati.single().messaggi.size)
    }

    @Test
    fun `la ricerca ignora maiuscole e minuscole`() {
        val trovati = cerca(conversazioni, "CORRIERE")

        assertEquals(luca, trovati.single().conversazione.numero)
    }

    @Test
    fun `un testo vuoto non trova niente`() {
        assertTrue(cerca(conversazioni, "   ").isEmpty())
    }

    @Test
    fun `un testo assente non trova niente`() {
        assertTrue(cerca(conversazioni, "inesistente").isEmpty())
    }
}
