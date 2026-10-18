package it.spamsaver

import android.telecom.Call
import android.telecom.CallScreeningService
import it.spamsaver.dominio.Chiamata
import it.spamsaver.dominio.Numerazione
import it.spamsaver.dominio.StatoTelefono
import it.spamsaver.dominio.decideChiamata
import it.spamsaver.dominio.numerazioneDi
import java.time.Instant
import java.time.LocalDate

/**
 * Decide delle chiamate in arrivo: respinge gli sconosciuti — il telefono non
 * squilla — e lascia passare chi è in rubrica. Ogni respinta finisce nello
 * storico dei respinti.
 *
 * Se lo sconosciuto va interrogato, manda l'SMS di identificazione una volta
 * sola per numero, col testo scelto dall'utente e dentro il tetto giornaliero.
 * Oltre il tetto respinge ancora ma non scrive, e lo dice all'utente. Numeri
 * brevi e premium non ricevono mai l'SMS (ADR-0002).
 */
class RifiutoChiamateService : CallScreeningService() {

    override fun onScreenCall(details: Call.Details) {
        val chiamata = Chiamata.daNumeroGrezzo(details.handle?.schemeSpecificPart)
        val numero = (chiamata as? Chiamata.Numero)?.numero
        val statoBase = Rubrica(this).statoPer(chiamata)

        val impostazioni = Impostazioni(this)
        val interrogati = ArchivioInterrogati(this)
        val invii = RegistroInvii(this)
        val oggi = LocalDate.now()
        val stato = if (numero == null) {
            statoBase
        } else {
            statoBase.copy(
                giaInterrogato = interrogati.giaInterrogato(numero),
                inviatiOggi = invii.inviatiOggi(oggi),
                tettoGiornaliero = impostazioni.tettoGiornaliero,
                numerazione = numerazioneDi(numero),
            )
        }

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

        if (numero == null || esito.passa) return

        if (esito.mandaSms) {
            if (InvioSms(this).manda(numero, impostazioni.testoSms)) {
                interrogati.segnaInterrogato(numero)
                invii.registra(oggi)
            }
        } else if (tettoRaggiunto(stato)) {
            impostazioni.ultimoTettoRaggiunto = Instant.now().toEpochMilli()
            Notifiche(this).tettoRaggiunto()
        }
    }

    /**
     * Il motivo per cui si è respinto senza scrivere è il tetto: il numero non
     * risultava già interrogato ed è di numerazione normale (gli altri casi
     * non avrebbero mai mandato l'SMS comunque).
     */
    private fun tettoRaggiunto(stato: StatoTelefono): Boolean =
        !stato.giaInterrogato &&
            stato.numerazione == Numerazione.Normale &&
            stato.inviatiOggi >= stato.tettoGiornaliero
}
