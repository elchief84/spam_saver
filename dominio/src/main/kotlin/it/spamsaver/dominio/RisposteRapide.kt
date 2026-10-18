package it.spamsaver.dominio

/**
 * Le risposte rapide configurate dall'utente: testi pronti da mandare da una
 * conversazione. Immutabile: [aggiungi] e [rimuovi] restituiscono un elenco
 * nuovo. I testi vuoti non entrano.
 */
data class RisposteRapide(val elenco: List<String> = emptyList()) {

    /** Aggiunge [testo] in coda, se non è vuoto e non c'è già. */
    fun aggiungi(testo: String): RisposteRapide {
        val pulito = testo.trim()
        if (pulito.isEmpty() || pulito in elenco) return this
        return copy(elenco = elenco + pulito)
    }

    /** Toglie [testo]; se non c'è non cambia niente. */
    fun rimuovi(testo: String): RisposteRapide {
        val pulito = testo.trim()
        if (pulito !in elenco) return this
        return copy(elenco = elenco - pulito)
    }
}
