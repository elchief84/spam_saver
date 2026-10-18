package it.spamsaver.dominio

/**
 * Le conversazioni archiviate: i numeri la cui conversazione è stata tolta
 * dall'elenco principale. Immutabile, come [StoricoRespinti]: [archivia] e
 * [ripristina] restituiscono un archivio nuovo e lasciano intatto quello di
 * partenza.
 */
data class ConversazioniArchiviate(val numeri: Set<NumeroTelefono> = emptySet()) {

    /** `true` se la conversazione con [numero] è archiviata. */
    fun contiene(numero: NumeroTelefono): Boolean = numero in numeri

    /** Archivia la conversazione con [numero]: esce dall'elenco principale. */
    fun archivia(numero: NumeroTelefono): ConversazioniArchiviate =
        copy(numeri = numeri + numero)

    /** Ripristina la conversazione con [numero]: torna nell'elenco principale. */
    fun ripristina(numero: NumeroTelefono): ConversazioniArchiviate =
        copy(numeri = numeri - numero)
}

/** Le conversazioni non archiviate, nell'ordine in cui arrivano: l'elenco principale. */
fun elencoPrincipale(
    conversazioni: List<Conversazione>,
    archiviate: ConversazioniArchiviate,
): List<Conversazione> = conversazioni.filterNot { archiviate.contiene(it.numero) }

/** Le conversazioni archiviate, nell'ordine in cui arrivano. */
fun conversazioniArchiviate(
    conversazioni: List<Conversazione>,
    archiviate: ConversazioniArchiviate,
): List<Conversazione> = conversazioni.filter { archiviate.contiene(it.numero) }
