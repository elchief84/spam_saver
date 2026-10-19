package it.spamsaver.dominio

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class RichiestaRuoloTest {

    /**
     * Il finto adattatore dei ruoli: dice se il ruolo c'è, se l'apertura riesce e
     * se alla fine il ruolo è stato concesso, e conta i tentativi. È il doppio
     * dell'adattatore vero, quello che parla con `RoleManager`.
     */
    private class FintoAdattatoreRuoli(
        private val disponibile: Boolean,
        private val aperturaRiesce: Boolean = true,
        private val ottenuto: Boolean = true,
    ) : AdattatoreRuoli {

        var aperture = 0
            private set

        override fun ruoloDisponibile(): Boolean = disponibile

        override fun apriRichiesta(): Boolean {
            aperture++
            return aperturaRiesce
        }

        override fun ruoloOttenuto(): Boolean = ottenuto
    }

    @Test
    fun `un ruolo disponibile apre la richiesta di sistema`() {
        val esito = chiediRuolo(FintoAdattatoreRuoli(disponibile = true))

        assertEquals(EsitoRichiestaRuolo.Aperta, esito)
    }

    @Test
    fun `un ruolo non disponibile chiede il messaggio, non il silenzio`() {
        val esito = chiediRuolo(FintoAdattatoreRuoli(disponibile = false))

        assertEquals(EsitoRichiestaRuolo.NonDisponibile, esito)
    }

    @Test
    fun `se la richiesta non si apre l'esito e lo stesso del ruolo non disponibile`() {
        val esito = chiediRuolo(FintoAdattatoreRuoli(disponibile = true, aperturaRiesce = false))

        assertEquals(EsitoRichiestaRuolo.NonDisponibile, esito)
    }

    @Test
    fun `un ruolo non disponibile non tenta nemmeno di aprire la richiesta`() {
        val adattatore = FintoAdattatoreRuoli(disponibile = false)

        chiediRuolo(adattatore)

        assertEquals(0, adattatore.aperture)
    }

    @Test
    fun `la richiesta partita che non concede il ruolo chiede il messaggio, non il silenzio`() {
        // Il caso del Mi 9: la richiesta si apre, ma al ritorno il ruolo non c'è.
        val adattatore = FintoAdattatoreRuoli(disponibile = true, ottenuto = false)

        chiediRuolo(adattatore)

        assertEquals(EsitoRitornoRuolo.NonConcesso, esitoAlRitorno(adattatore))
    }

    @Test
    fun `la richiesta partita che concede il ruolo lascia proseguire`() {
        val adattatore = FintoAdattatoreRuoli(disponibile = true, ottenuto = true)

        chiediRuolo(adattatore)

        assertEquals(EsitoRitornoRuolo.Concesso, esitoAlRitorno(adattatore))
    }

    @Test
    fun `il ruolo non concesso ripiega sulle app predefinite`() {
        // Il caso del Mi 9: la richiesta si apre, ma al ritorno il ruolo non c'è.
        // Il percorso a mano «App → Accesso speciale → Caller ID e spam» non
        // esiste: il ripiego è l'azione che apre le app predefinite.
        val adattatore = FintoAdattatoreRuoli(disponibile = true, ottenuto = false)

        chiediRuolo(adattatore)

        assertEquals(RipiegoRuolo.ApriAppPredefinite, ripiegoRuolo(esitoAlRitorno(adattatore)))
    }

    @Test
    fun `il ruolo concesso non chiede nessun ripiego`() {
        val adattatore = FintoAdattatoreRuoli(disponibile = true, ottenuto = true)

        chiediRuolo(adattatore)

        assertNull(ripiegoRuolo(esitoAlRitorno(adattatore)))
    }
}
