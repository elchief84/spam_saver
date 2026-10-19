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

/**
 * Una via d'uscita dal passo che chiede un ruolo di sistema, quando la richiesta
 * non ha concesso il ruolo.
 */
enum class ViaDUscitaRuolo {

    /** Proseguire con il resto dell'onboarding, senza il ruolo. */
    Prosegui,

    /**
     * Aprire la schermata di sistema «App predefinite», dove il gestore SMS si
     * assegna a mano.
     */
    AppPredefinite,
}

/**
 * Decide le vie d'uscita del passo «gestore SMS predefinito» quando la richiesta
 * non ha concesso il ruolo.
 *
 * È pura: si appoggia a [esitoAlRitorno] per sapere se il ruolo è ora dell'app.
 * Sul Mi 9 la richiesta del ruolo SMS si apre e poi non concede mai il ruolo,
 * come per lo screening delle chiamate: il passo deve dirlo e offrire di
 * proseguire o di aprire «App predefinite», invece di restare muto. Quando il
 * ruolo c'è non serve nessuna uscita.
 */
fun vieDUscitaRuoloSms(adattatore: AdattatoreRuoli): List<ViaDUscitaRuolo> =
    when (esitoAlRitorno(adattatore)) {
        EsitoRitornoRuolo.Concesso -> emptyList()
        EsitoRitornoRuolo.NonConcesso ->
            listOf(ViaDUscitaRuolo.AppPredefinite, ViaDUscitaRuolo.Prosegui)
    }
