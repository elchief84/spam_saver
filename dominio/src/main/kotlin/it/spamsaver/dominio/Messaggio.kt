package it.spamsaver.dominio

import java.time.Instant

/** Un messaggio scambiato con [numero]: ricevuto o inviato da Spam Saver. */
data class Messaggio(
    val numero: NumeroTelefono,
    val testo: String,
    val quando: Instant,
    val inviato: Boolean,
)

/** I messaggi di un numero, in ordine di arrivo. */
data class Conversazione(val numero: NumeroTelefono, val messaggi: List<Messaggio>)

/** Raggruppa i messaggi per numero, i più recenti per primi. */
fun conversazioniDi(messaggi: List<Messaggio>): List<Conversazione> =
    messaggi.groupBy { it.numero }
        .map { (numero, elenco) -> Conversazione(numero, elenco.sortedBy { it.quando }) }
        .sortedByDescending { it.messaggi.last().quando }
