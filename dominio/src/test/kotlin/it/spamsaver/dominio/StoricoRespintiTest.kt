package it.spamsaver.dominio

import java.time.Instant
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class StoricoRespintiTest {

    private fun numero(canonico: String): NumeroTelefono =
        requireNotNull(NumeroTelefono.da(canonico)) { "numero di test non valido: $canonico" }

    private val respinta = EsitoChiamata(passa = false, mandaSms = false)
    private val quando = Instant.parse("2026-10-18T09:30:00Z")

    @Test
    fun `una chiamata respinta entra nello storico col numero e il momento`() {
        val chiamata = Chiamata.daNumeroGrezzo("+39 333 123 4567")

        val storico = StoricoRespinti().registra(chiamata, respinta, quando)

        assertEquals(listOf(Respinto(numero("3331234567"), quando)), storico.elenco)
    }

    @Test
    fun `una chiamata che passa non entra nello storico`() {
        val chiamata = Chiamata.daNumeroGrezzo("3331234567")

        val storico = StoricoRespinti().registra(
            chiamata,
            EsitoChiamata(passa = true, mandaSms = false),
            quando,
        )

        assertTrue(storico.elenco.isEmpty())
    }

    @Test
    fun `le respinte si accumulano in ordine di arrivo`() {
        val secondo = Instant.parse("2026-10-18T09:31:00Z")

        val storico = StoricoRespinti()
            .registra(Chiamata.daNumeroGrezzo("3331234567"), respinta, quando)
            .registra(Chiamata.daNumeroGrezzo("0612345678"), respinta, secondo)

        assertEquals(
            listOf(
                Respinto(numero("3331234567"), quando),
                Respinto(numero("0612345678"), secondo),
            ),
            storico.elenco,
        )
    }

    @Test
    fun `uno sconosciuto respinto dalla decisione entra nello storico`() {
        val chiamata = Chiamata.daNumeroGrezzo("3331234567")
        val esito = decideChiamata(chiamata, StatoTelefono())

        val storico = StoricoRespinti().registra(chiamata, esito, quando)

        assertEquals(listOf(Respinto(numero("3331234567"), quando)), storico.elenco)
    }

    @Test
    fun `un numero in rubrica che passa non entra nello storico`() {
        val chiamata = Chiamata.daNumeroGrezzo("3331234567")
        val esito = decideChiamata(chiamata, StatoTelefono(inRubrica = setOf(numero("3331234567"))))

        val storico = StoricoRespinti().registra(chiamata, esito, quando)

        assertTrue(storico.elenco.isEmpty())
    }
}
