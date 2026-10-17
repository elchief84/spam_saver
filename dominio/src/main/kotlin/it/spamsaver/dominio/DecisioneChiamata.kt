package it.spamsaver.dominio

/**
 * L'esito della decisione su una chiamata in arrivo.
 *
 * @property passa `true` se la chiamata deve squillare.
 * @property mandaSms `true` se va inviato l'SMS di identificazione.
 */
data class EsitoChiamata(
    val passa: Boolean,
    val mandaSms: Boolean,
)

/**
 * Decide cosa fare di una chiamata in arrivo.
 *
 * È pura: niente Android, niente orologio, niente database, niente rete. Prende
 * la chiamata e ciò che il telefono sa, e restituisce solo l'esito. Tutto il
 * resto — applicare il rifiuto, inviare l'SMS, scrivere lo storico — vive fuori
 * di questa funzione.
 *
 * Regole:
 * - numero nascosto, non interpretabile, in rubrica o in whitelist → passa;
 * - altrimenti respinge, e manda l'SMS solo se il numero non è già interrogato,
 *   la numerazione è normale e il tetto di oggi non è raggiunto.
 */
fun decideChiamata(chiamata: Chiamata, stato: StatoTelefono): EsitoChiamata = when (chiamata) {
    // Non respingiamo per una lacuna o un errore nostro: la chiamata passa.
    Chiamata.Nascosta,
    Chiamata.NonInterpretabile,
    -> EsitoChiamata(passa = true, mandaSms = false)

    is Chiamata.Numero -> decideNumeroSconosciuto(chiamata.numero, stato)
}

private fun decideNumeroSconosciuto(numero: NumeroTelefono, stato: StatoTelefono): EsitoChiamata {
    if (stato.conosce(numero)) return EsitoChiamata(passa = true, mandaSms = false)

    val mandaSms = !stato.giaInterrogato &&
        stato.numerazione == Numerazione.Normale &&
        stato.inviatiOggi < stato.tettoGiornaliero

    return EsitoChiamata(passa = false, mandaSms = mandaSms)
}
