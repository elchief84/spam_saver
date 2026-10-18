package it.spamsaver.dominio

import java.time.Instant
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class BloccatiTest {

    private fun numero(canonico: String): NumeroTelefono =
        requireNotNull(NumeroTelefono.da(canonico)) { "numero di test non valido: $canonico" }

    private val luca = numero("3331234567")

    private val messaggio = Messaggio(
        luca,
        "Ciao, chi sei?",
        Instant.parse("2026-10-18T09:00:00Z"),
        inviato = false,
    )

    @Test
    fun `un mittente bloccato non si notifica`() {
        val bloccati = Bloccati().blocca(luca)

        assertTrue(bloccati.contiene(luca))
        assertFalse(deveNotificare(messaggio, bloccati))
    }

    @Test
    fun `un mittente non bloccato si notifica`() {
        assertTrue(deveNotificare(messaggio, Bloccati()))
    }

    @Test
    fun `un mittente sbloccato torna a notificarsi`() {
        val bloccati = Bloccati().blocca(luca).sblocca(luca)

        assertFalse(bloccati.contiene(luca))
        assertTrue(deveNotificare(messaggio, bloccati))
    }

    @Test
    fun `il blocco vale solo per il mittente bloccato`() {
        val altro = numero("0612345678")

        assertTrue(deveNotificare(messaggio, Bloccati().blocca(altro)))
    }
}
