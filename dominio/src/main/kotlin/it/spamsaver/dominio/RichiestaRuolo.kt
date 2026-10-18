package it.spamsaver.dominio

/**
 * L'adattatore verso i ruoli di sistema del telefono.
 *
 * La decisione pura non sa cosa sia Android: chiede all'adattatore, che a sua
 * volta parla con `RoleManager`. Nei test si usa un finto adattatore.
 */
interface AdattatoreRuoli {

    /** `true` se questo telefono conosce e offre il ruolo. */
    fun ruoloDisponibile(): Boolean

    /**
     * Apre la richiesta di sistema per il ruolo; `true` solo se l'attività si è
     * aperta davvero. Non solleva eccezioni: se non c'è nessuna attività che la
     * raccolga, risponde `false`.
     */
    fun apriRichiesta(): Boolean
}

/** Come è andata la richiesta di un ruolo di sistema. */
enum class EsitoRichiestaRuolo {

    /** La richiesta di sistema si è aperta: l'utente la vede. */
    Aperta,

    /**
     * Il ruolo non c'è, o la richiesta non si è aperta: va mostrato un messaggio
     * che lo dice, invece di lasciare l'onboarding muto.
     */
    NonDisponibile,
}

/**
 * Decide cosa fare quando l'utente chiede un ruolo di sistema in onboarding.
 *
 * È pura: niente Android, niente schermo. Se il ruolo è disponibile apre la
 * richiesta e riferisce se si è aperta; se manca — o se aprirla fallisce, come
 * quando `RoleManager` non c'è o nessuna attività raccoglie l'intent — l'esito è
 * [EsitoRichiestaRuolo.NonDisponibile]. Così l'onboarding mostra come
 * proseguire invece di restare fermo su un pulsante che non fa niente.
 */
fun chiediRuolo(adattatore: AdattatoreRuoli): EsitoRichiestaRuolo =
    if (adattatore.ruoloDisponibile() && adattatore.apriRichiesta()) {
        EsitoRichiestaRuolo.Aperta
    } else {
        EsitoRichiestaRuolo.NonDisponibile
    }
