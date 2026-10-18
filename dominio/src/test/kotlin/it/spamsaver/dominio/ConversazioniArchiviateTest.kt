package it.spamsaver.dominio

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ConversazioniArchiviateTest {

    private fun numero(canonico: String): NumeroTelefono =
        requireNotNull(NumeroTelefono.da(canonico)) { "numero di test non valido: $canonico" }

    private val luca = numero("3331234567")
    private val anna = numero("0612345678")

    private val conversazioni = listOf(
        Conversazione(luca, emptyList()),
        Conversazione(anna, emptyList()),
    )

    @Test
    fun `una conversazione archiviata esce dall'elenco principale`() {
        val archiviate = ConversazioniArchiviate().archivia(luca)

        assertTrue(archiviate.contiene(luca))
        assertEquals(listOf(anna), elencoPrincipale(conversazioni, archiviate).map { it.numero })
    }

    @Test
    fun `una conversazione archiviata si ritrova fra le archiviate`() {
        val archiviate = ConversazioniArchiviate().archivia(luca)

        assertEquals(listOf(luca), conversazioniArchiviate(conversazioni, archiviate).map { it.numero })
    }

    @Test
    fun `una conversazione ripristinata torna nell'elenco principale`() {
        val archiviate = ConversazioniArchiviate().archivia(luca).ripristina(luca)

        assertFalse(archiviate.contiene(luca))
        assertEquals(
            listOf(luca, anna),
            elencoPrincipale(conversazioni, archiviate).map { it.numero },
        )
    }
}
