package it.spamsaver.dominio

import org.junit.Assert.assertEquals
import org.junit.Test

class RichiestaRuoloTest {

    /**
     * Il finto adattatore dei ruoli: dice se il ruolo c'è e se l'apertura riesce,
     * e conta i tentativi. È il doppio dell'adattatore vero, quello che parla
     * con `RoleManager`.
     */
    private class FintoAdattatoreRuoli(
        private val disponibile: Boolean,
        private val aperturaRiesce: Boolean = true,
    ) : AdattatoreRuoli {

        var aperture = 0
            private set

        override fun ruoloDisponibile(): Boolean = disponibile

        override fun apriRichiesta(): Boolean {
            aperture++
            return aperturaRiesce
        }
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
}
