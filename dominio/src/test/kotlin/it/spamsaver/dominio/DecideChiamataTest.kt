package it.spamsaver.dominio

import org.junit.Assert.assertEquals
import org.junit.Test

class DecideChiamataTest {

    private fun numero(canonico: String): NumeroTelefono =
        requireNotNull(NumeroTelefono.da(canonico)) { "numero di test non valido: $canonico" }

    private fun stato(
        inRubrica: Set<String> = emptySet(),
        inWhitelist: Set<String> = emptySet(),
        giaInterrogato: Boolean = false,
        inviatiOggi: Int = 0,
        tettoGiornaliero: Int = TETTO_GIORNALIERO_PREDEFINITO,
        numerazione: Numerazione = Numerazione.Normale,
    ): StatoTelefono = StatoTelefono(
        inRubrica = inRubrica.map(::numero).toSet(),
        inWhitelist = inWhitelist.map(::numero).toSet(),
        giaInterrogato = giaInterrogato,
        inviatiOggi = inviatiOggi,
        tettoGiornaliero = tettoGiornaliero,
        numerazione = numerazione,
    )

    private val passa = EsitoChiamata(passa = true, mandaSms = false)
    private val respintaSenzaSms = EsitoChiamata(passa = false, mandaSms = false)
    private val respintaConSms = EsitoChiamata(passa = false, mandaSms = true)

    @Test
    fun `un numero in rubrica passa e non riceve l'SMS`() {
        val esito = decideChiamata(
            Chiamata.daNumeroGrezzo("3331234567"),
            stato(inRubrica = setOf("3331234567")),
        )
        assertEquals(passa, esito)
    }

    @Test
    fun `un numero in whitelist passa e non riceve l'SMS`() {
        val esito = decideChiamata(
            Chiamata.daNumeroGrezzo("3331234567"),
            stato(inWhitelist = setOf("3331234567")),
        )
        assertEquals(passa, esito)
    }

    @Test
    fun `un numero sconosciuto viene respinto e riceve l'SMS`() {
        val esito = decideChiamata(
            Chiamata.daNumeroGrezzo("3331234567"),
            stato(),
        )
        assertEquals(respintaConSms, esito)
    }

    @Test
    fun `una chiamata nascosta passa`() {
        val esito = decideChiamata(Chiamata.daNumeroGrezzo(null), stato())
        assertEquals(passa, esito)
    }

    @Test
    fun `un numero non interpretabile passa`() {
        val esito = decideChiamata(Chiamata.daNumeroGrezzo("sconosciuto"), stato())
        assertEquals(passa, esito)
    }

    @Test
    fun `un numero gia interrogato viene respinto ma non riceve un secondo SMS`() {
        val esito = decideChiamata(
            Chiamata.daNumeroGrezzo("3331234567"),
            stato(giaInterrogato = true),
        )
        assertEquals(respintaSenzaSms, esito)
    }

    @Test
    fun `una numerazione breve viene respinta senza SMS`() {
        val esito = decideChiamata(
            Chiamata.daNumeroGrezzo("112"),
            stato(numerazione = Numerazione.Breve),
        )
        assertEquals(respintaSenzaSms, esito)
    }

    @Test
    fun `una numerazione premium viene respinta senza SMS`() {
        val esito = decideChiamata(
            Chiamata.daNumeroGrezzo("899123456"),
            stato(numerazione = Numerazione.Premium),
        )
        assertEquals(respintaSenzaSms, esito)
    }

    @Test
    fun `raggiunto il tetto di oggi si respinge ancora ma non si scrive`() {
        val esito = decideChiamata(
            Chiamata.daNumeroGrezzo("3331234567"),
            stato(inviatiOggi = 20, tettoGiornaliero = 20),
        )
        assertEquals(respintaSenzaSms, esito)
    }

    @Test
    fun `sotto il tetto di oggi l'SMS parte`() {
        val esito = decideChiamata(
            Chiamata.daNumeroGrezzo("3331234567"),
            stato(inviatiOggi = 19, tettoGiornaliero = 20),
        )
        assertEquals(respintaConSms, esito)
    }

    @Test
    fun `un numero con prefisso internazionale e spazi e riconosciuto se in rubrica`() {
        // "+39 333 123 4567" e "3331234567" sono lo stesso numero: se quello in
        // rubrica passa, deve passare anche la sua scrittura internazionale.
        val esito = decideChiamata(
            Chiamata.daNumeroGrezzo("+39 333 123 4567"),
            stato(inRubrica = setOf("3331234567")),
        )
        assertEquals(passa, esito)
    }

    @Test
    fun `un numero con prefisso internazionale e spazi e riconosciuto se in whitelist`() {
        // La stessa normalizzazione vale per la whitelist: le due strade di
        // sblocco devono riconoscere il numero allo stesso modo.
        val esito = decideChiamata(
            Chiamata.daNumeroGrezzo("+39 333 123 4567"),
            stato(inWhitelist = setOf("3331234567")),
        )
        assertEquals(passa, esito)
    }

    @Test
    fun `un numero tolto dalla whitelist torna a essere respinto`() {
        val numero = numero("3331234567")

        val inWhitelist = decideChiamata(
            Chiamata.Numero(numero),
            stato(inWhitelist = setOf("3331234567")),
        )
        val fuoriWhitelist = decideChiamata(
            Chiamata.Numero(numero),
            stato(inWhitelist = emptySet()),
        )

        assertEquals(passa, inWhitelist)
        assertEquals(respintaConSms, fuoriWhitelist)
    }
}
