package it.spamsaver.dominio

/**
 * Un numero di telefono in **forma canonica**, pronto per i confronti.
 *
 * Due scritture dello stesso numero — con o senza prefisso internazionale, con
 * spazi o separatori — danno lo stesso [NumeroTelefono]: così il confronto con
 * la rubrica e la whitelist funziona davvero (storia utente 26).
 */
@JvmInline
value class NumeroTelefono private constructor(val canonico: String) {

    override fun toString(): String = canonico

    companion object {
        private val SEPARATORI = Regex("[\\s().\\-/]+")
        private const val PREFISSO_INTERNAZIONALE = "00"
        private const val PREFISSO_ITALIA = "39"

        /**
         * Riduce [grezzo] alla forma canonica, oppure restituisce `null` se non
         * è interpretabile: contiene caratteri che non sono cifre o separatori,
         * oppure non resta nessuna cifra.
         */
        fun da(grezzo: String): NumeroTelefono? {
            var cifre = grezzo.trim().replace(SEPARATORI, "")
            if (cifre.isEmpty()) return null

            // Il prefisso internazionale si scrive "00" oppure "+".
            if (cifre.startsWith(PREFISSO_INTERNAZIONALE)) {
                cifre = "+" + cifre.removePrefix(PREFISSO_INTERNAZIONALE)
            }
            val internazionale = cifre.startsWith("+")
            if (internazionale) cifre = cifre.removePrefix("+")

            if (cifre.isEmpty() || !cifre.all { it.isDigit() }) return null

            // In Italia "+39 06 1234567" e "06 1234567" sono lo stesso numero:
            // per confrontare si toglie il prefisso del paese.
            if (internazionale && cifre.startsWith(PREFISSO_ITALIA)) {
                cifre = cifre.removePrefix(PREFISSO_ITALIA)
                if (cifre.isEmpty()) return null
            }

            return NumeroTelefono(cifre)
        }
    }
}
