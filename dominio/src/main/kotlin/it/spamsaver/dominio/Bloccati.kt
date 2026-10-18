package it.spamsaver.dominio

/**
 * I mittenti bloccati: i numeri di cui l'utente non vuole ricevere le
 * notifiche. Bloccare un mittente **non** respinge le sue chiamate — respingere
 * gli sconosciuti è già il comportamento predefinito, e un numero in rubrica o
 * in whitelist continua a passare: significa solo che i suoi SMS non si
 * notificano, pur restando nella conversazione.
 *
 * È immutabile, come [StoricoRespinti]: [blocca] e [sblocca] restituiscono un
 * insieme nuovo.
 */
data class Bloccati(val numeri: Set<NumeroTelefono> = emptySet()) {

    /** `true` se [numero] è bloccato. */
    fun contiene(numero: NumeroTelefono): Boolean = numero in numeri

    /** Blocca [numero]. */
    fun blocca(numero: NumeroTelefono): Bloccati = copy(numeri = numeri + numero)

    /** Sblocca [numero]; se non era bloccato non cambia niente. */
    fun sblocca(numero: NumeroTelefono): Bloccati = copy(numeri = numeri - numero)
}

/**
 * `true` se l'SMS di [messaggio] va notificato: un mittente bloccato non si
 * notifica. Il messaggio va comunque registrato nella conversazione — il blocco
 * riguarda la notifica, non la lettura.
 */
fun deveNotificare(messaggio: Messaggio, bloccati: Bloccati): Boolean =
    !bloccati.contiene(messaggio.numero)
