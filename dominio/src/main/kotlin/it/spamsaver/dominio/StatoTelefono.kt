package it.spamsaver.dominio

/** Tetto giornaliero predefinito agli SMS di identificazione (spec). */
const val TETTO_GIORNALIERO_PREDEFINITO = 20

/** Come il telefono classifica una numerazione. */
enum class Numerazione {
    /** Un numero normale: l'SMS di identificazione ha senso. */
    Normale,

    /** Un numero breve (servizi, emergenze): non deve ricevere SMS. */
    Breve,

    /** Un numero premium: l'SMS costerebbe molto più del normale. */
    Premium,
}

/**
 * Quello che il telefono sa di sé al momento della chiamata, già risolto fuori
 * dalla funzione pura: i numeri conosciuti, la memoria degli interrogati e la
 * spesa di oggi.
 */
data class StatoTelefono(
    val inRubrica: Set<NumeroTelefono> = emptySet(),
    val inWhitelist: Set<NumeroTelefono> = emptySet(),
    val giaInterrogato: Boolean = false,
    val inviatiOggi: Int = 0,
    val tettoGiornaliero: Int = TETTO_GIORNALIERO_PREDEFINITO,
    val numerazione: Numerazione = Numerazione.Normale,
) {
    /** Il numero è conosciuto: in rubrica o in whitelist. */
    fun conosce(numero: NumeroTelefono): Boolean =
        numero in inRubrica || numero in inWhitelist
}
