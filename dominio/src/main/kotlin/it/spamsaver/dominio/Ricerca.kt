package it.spamsaver.dominio

/**
 * Una conversazione trovata dalla ricerca: la conversazione intera e i suoi
 * messaggi che contengono il testo cercato.
 */
data class ConversazioneTrovata(
    val conversazione: Conversazione,
    val messaggi: List<Messaggio>,
)

/**
 * Cerca [testo] nel contenuto dei messaggi e restituisce le conversazioni che
 * lo contengono, ciascuna coi soli messaggi che lo contengono. La ricerca non
 * distingue maiuscole e minuscole; un testo vuoto non trova niente.
 */
fun cerca(conversazioni: List<Conversazione>, testo: String): List<ConversazioneTrovata> {
    val cercato = testo.trim()
    if (cercato.isEmpty()) return emptyList()

    return conversazioni.mapNotNull { conversazione ->
        val trovati = conversazione.messaggi.filter { it.testo.contains(cercato, ignoreCase = true) }
        if (trovati.isEmpty()) null else ConversazioneTrovata(conversazione, trovati)
    }
}
