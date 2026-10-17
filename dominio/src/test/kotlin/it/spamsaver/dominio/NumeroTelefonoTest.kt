package it.spamsaver.dominio

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class NumeroTelefonoTest {

    @Test
    fun `lo stesso numero scritto in modi diversi ha la stessa forma canonica`() {
        assertEquals(NumeroTelefono.da("333 123 4567"), NumeroTelefono.da("3331234567"))
        assertEquals(NumeroTelefono.da("3331234567"), NumeroTelefono.da("+39 333 123 4567"))
        assertEquals(NumeroTelefono.da("3331234567"), NumeroTelefono.da("0039 333-123-4567"))
        assertEquals(NumeroTelefono.da("0612345678"), NumeroTelefono.da("+39 (06) 1234 5678"))
    }

    @Test
    fun `i separatori vengono ignorati`() {
        assertEquals(NumeroTelefono.da("02.1234.5678"), NumeroTelefono.da("02 1234 5678"))
    }

    @Test
    fun `un testo che non e un numero non e interpretabile`() {
        assertNull(NumeroTelefono.da("sconosciuto"))
        assertNull(NumeroTelefono.da("+"))
        assertNull(NumeroTelefono.da("   "))
        assertNull(NumeroTelefono.da("+39 "))
    }

    @Test
    fun `una chiamata senza numero e nascosta`() {
        assertEquals(Chiamata.Nascosta, Chiamata.daNumeroGrezzo(null))
        assertEquals(Chiamata.Nascosta, Chiamata.daNumeroGrezzo(""))
        assertEquals(Chiamata.Nascosta, Chiamata.daNumeroGrezzo("   "))
    }

    @Test
    fun `una chiamata con un numero illeggibile e non interpretabile`() {
        assertEquals(Chiamata.NonInterpretabile, Chiamata.daNumeroGrezzo("sconosciuto"))
    }

    @Test
    fun `una chiamata con un numero valido porta il numero canonico`() {
        assertEquals(
            Chiamata.Numero(requireNotNull(NumeroTelefono.da("3331234567"))),
            Chiamata.daNumeroGrezzo("+39 333 123 4567"),
        )
    }
}
