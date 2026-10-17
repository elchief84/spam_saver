package it.spamsaver.dominio

/** Una chiamata in arrivo, come la presenta il telefono. */
sealed interface Chiamata {

    /** Il numero è leggibile: eccolo in forma canonica. */
    data class Numero(val numero: NumeroTelefono) : Chiamata

    /** Il numero non c'è: privato, anonimo o nascosto. */
    data object Nascosta : Chiamata

    /** Il numero c'è, ma non si riesce a leggerlo. */
    data object NonInterpretabile : Chiamata

    companion object {
        /**
         * Costruisce la [Chiamata] dal numero grezzo letto dal telefono:
         * assente o vuoto → [Nascosta], illeggibile → [NonInterpretabile].
         */
        fun daNumeroGrezzo(grezzo: String?): Chiamata = when {
            grezzo.isNullOrBlank() -> Nascosta
            else -> NumeroTelefono.da(grezzo)?.let(::Numero) ?: NonInterpretabile
        }
    }
}
