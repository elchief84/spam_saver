package it.spamsaver.dominio

import java.time.Instant

/** Una chiamata respinta: il numero che ha chiamato e quando. */
data class Respinto(
    val numero: NumeroTelefono,
    val quando: Instant,
)

/**
 * Lo storico dei respinti: le chiamate respinte, in ordine di arrivo.
 *
 * È immutabile — [registra] restituisce uno storico nuovo e lascia intatto quello
 * di partenza — così la regola «ogni respinta è registrata» resta pura e la
 * scrittura su disco vive fuori dal dominio.
 */
data class StoricoRespinti(val elenco: List<Respinto> = emptyList()) {

    /**
     * Registra il rifiuto se la chiamata non passa; una chiamata che passa lascia
     * lo storico com'è. Solo un numero leggibile può essere respinto, quindi solo
     * un numero leggibile entra nello storico.
     */
    fun registra(chiamata: Chiamata, esito: EsitoChiamata, quando: Instant): StoricoRespinti {
        if (esito.passa) return this
        val numero = (chiamata as? Chiamata.Numero)?.numero ?: return this
        return copy(elenco = elenco + Respinto(numero, quando))
    }
}
