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

    /**
     * `true` se l'app ha ora il ruolo: la richiesta di sistema è andata a buon
     * fine. Serve al ritorno nell'app, quando la richiesta è già partita.
     */
    fun ruoloOttenuto(): Boolean
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

/** Com'è andata la richiesta di un ruolo di sistema, al ritorno nell'app. */
enum class EsitoRitornoRuolo {

    /** Il ruolo ora è dell'app: l'onboarding prosegue. */
    Concesso,

    /**
     * La richiesta era partita ma il ruolo non c'è: va mostrato un messaggio che
     * lo dice, invece di lasciare l'onboarding muto.
     */
    NonConcesso,
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

/**
 * Decide se la richiesta di un ruolo è andata a buon fine quando l'utente torna
 * nell'app.
 *
 * È pura: chiede all'adattatore se il ruolo è ora dell'app. Su alcuni telefoni
 * — il Mi 9 con Android 10 e MIUI, per esempio — la richiesta si apre ma il
 * ruolo non viene mai concesso: la schermata di sistema non compare o si
 * annulla, mentre [AdattatoreRuoli.apriRichiesta] ha già risposto `true` e
 * [chiediRuolo] dice [EsitoRichiestaRuolo.Aperta]. È al ritorno che il caso si
 * distingue dal successo: se il ruolo non c'è, l'esito è
 * [EsitoRitornoRuolo.NonConcesso] e l'onboarding mostra il messaggio, invece di
 * restare muto.
 */
fun esitoAlRitorno(adattatore: AdattatoreRuoli): EsitoRitornoRuolo =
    if (adattatore.ruoloOttenuto()) {
        EsitoRitornoRuolo.Concesso
    } else {
        EsitoRitornoRuolo.NonConcesso
    }

/** Cosa offrire quando il ruolo di screening delle chiamate non è dell'app. */
enum class RipiegoRuolo {

    /**
     * Offre di aprire le impostazioni di sistema delle app predefinite, dove si
     * assegna il ruolo di «Caller ID e spam». Un'azione che apre la schermata
     * giusta non dipende dal percorso a mano — «App → Accesso speciale → Caller ID
     * e spam» — che su alcuni telefoni, come il Mi 9 con MIUI, non esiste.
     */
    ApriAppPredefinite,
}

/**
 * Decide come proseguire quando il ruolo di screening non è stato concesso.
 *
 * È pura: niente Android, niente schermo. Se il ruolo è dell'app non c'è niente
 * da offrire; se non lo è — il caso del Mi 9, dove la richiesta si apre ma il
 * ruolo resta «None» — il ripiego è [RipiegoRuolo.ApriAppPredefinite], l'azione
 * che apre le app predefinite, invece di un percorso a mano che su quel telefono
 * non esiste.
 */
fun ripiegoRuolo(esito: EsitoRitornoRuolo): RipiegoRuolo? = when (esito) {
    EsitoRitornoRuolo.Concesso -> null
    EsitoRitornoRuolo.NonConcesso -> RipiegoRuolo.ApriAppPredefinite
}
