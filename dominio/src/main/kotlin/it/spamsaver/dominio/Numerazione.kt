package it.spamsaver.dominio

/**
 * Classifica la numerazione di [numero] senza Android.
 *
 * L'SMS di identificazione ha senso solo verso una numerazione normale: un
 * numero breve (emergenze, servizi) non lo legge nessuno e un numero premium lo
 * farebbe pagare molto più del normale (ADR-0002). La regola è pura, così la
 * decisione della chiamata resta provabile senza il telefono.
 */
fun numerazioneDi(numero: NumeroTelefono): Numerazione = when {
    numero.canonico.length <= LUNGHEZZA_MASSIMA_BREVE -> Numerazione.Breve
    PREFISSI_PREMIUM.any { numero.canonico.startsWith(it) } -> Numerazione.Premium
    else -> Numerazione.Normale
}

/** I numeri brevi italiani non superano le cinque cifre. */
private const val LUNGHEZZA_MASSIMA_BREVE = 5

/**
 * I prefissi italiani delle numerazioni premium e a tariffazione speciale:
 * 144, 166, 199, 89x. Non sono numeri che un SMS di identificazione deve
 * raggiungere.
 */
private val PREFISSI_PREMIUM = listOf("144", "166", "199", "89")
