package it.spamsaver

import android.telecom.Call
import android.telecom.CallScreeningService
import it.spamsaver.dominio.Chiamata
import it.spamsaver.dominio.decideChiamata
import java.time.Instant

/**
 * Decide delle chiamate in arrivo: respinge gli sconosciuti — il telefono non
 * squilla — e lascia passare chi è in rubrica. Ogni respinta finisce nello
 * storico dei respinti.
 *
 * Nessun SMS parte da qui: l'SMS di identificazione arriva col ticket 4, e
 * `EsitoChiamata.mandaSms` per ora si ignora di proposito.
 */
class RifiutoChiamateService : CallScreeningService() {

    override fun onScreenCall(details: Call.Details) {
        val chiamata = Chiamata.daNumeroGrezzo(details.handle?.schemeSpecificPart)
        val stato = Rubrica(this).statoPer(chiamata)
            .copy(inWhitelist = ArchivioWhitelist(this).leggi())
        val esito = decideChiamata(chiamata, stato)

        respondToCall(
            details,
            if (esito.passa) {
                CallResponse.Builder().build()
            } else {
                CallResponse.Builder()
                    .setDisallowCall(true)
                    .setRejectCall(true)
                    .setSkipCallLog(false)
                    .setSkipNotification(true)
                    .build()
            },
        )

        ArchivioRespinti(this).registra(chiamata, esito, Instant.now())
    }
}
