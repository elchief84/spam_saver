package it.spamsaver.dominio

import org.junit.Assert.assertEquals
import org.junit.Test

class NumerazioneTest {

    private fun numerazione(grezzo: String): Numerazione =
        numerazioneDi(requireNotNull(NumeroTelefono.da(grezzo)) { "numero di test non valido: $grezzo" })

    @Test
    fun `un numero di telefono normale e una numerazione normale`() {
        assertEquals(Numerazione.Normale, numerazione("3331234567"))
        assertEquals(Numerazione.Normale, numerazione("0612345678"))
    }

    @Test
    fun `un numero breve e una numerazione breve`() {
        assertEquals(Numerazione.Breve, numerazione("112"))
        assertEquals(Numerazione.Breve, numerazione("80012"))
    }

    @Test
    fun `un numero premium e una numerazione premium`() {
        assertEquals(Numerazione.Premium, numerazione("899123456"))
        assertEquals(Numerazione.Premium, numerazione("144123456"))
        assertEquals(Numerazione.Premium, numerazione("166123456"))
        assertEquals(Numerazione.Premium, numerazione("199123456"))
    }

    @Test
    fun `il prefisso internazionale non cambia la numerazione`() {
        assertEquals(Numerazione.Normale, numerazione("+39 333 123 4567"))
        assertEquals(Numerazione.Premium, numerazione("+39 899 123 456"))
    }
}
