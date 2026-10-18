package it.spamsaver.dominio

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class RisposteRapideTest {

    @Test
    fun `una risposta rapida si aggiunge in coda`() {
        val risposte = RisposteRapide().aggiungi("Ci sono").aggiungi("Ti richiamo")

        assertEquals(listOf("Ci sono", "Ti richiamo"), risposte.elenco)
    }

    @Test
    fun `una risposta rapida vuota non entra`() {
        assertTrue(RisposteRapide().aggiungi("   ").elenco.isEmpty())
    }

    @Test
    fun `una risposta rapida non entra due volte`() {
        val risposte = RisposteRapide().aggiungi("Ci sono").aggiungi("Ci sono")

        assertEquals(listOf("Ci sono"), risposte.elenco)
    }

    @Test
    fun `una risposta rapida si rimuove`() {
        val risposte = RisposteRapide().aggiungi("Ci sono").aggiungi("Ti richiamo").rimuovi("Ci sono")

        assertEquals(listOf("Ti richiamo"), risposte.elenco)
    }
}
