package it.spamsaver

import android.Manifest
import android.app.role.RoleManager
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.Button
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import it.spamsaver.dominio.NumeroTelefono
import it.spamsaver.dominio.Respinto
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter

/** I passi dell'onboarding, nell'ordine in cui Android li impone. */
private enum class Passo { Chiamate, Rubrica, Sms, PermessoSms, Notifiche, Fatto }

/** Le tre sezioni della schermata principale. */
private enum class Sezione { Chiamate, Messaggi, Impostazioni }

/**
 * L'unica schermata dell'app.
 *
 * L'onboarding chiede prima il ruolo di screening delle chiamate, poi la
 * rubrica, poi — avvisando del costo — il ruolo di gestore SMS e i permessi che
 * ne dipendono. Quando non manca niente, la schermata mostra le chiamate
 * respinte e la whitelist — da qui si sblocca un numero o lo si rimette fuori —
 * le conversazioni e le impostazioni dell'SMS di identificazione.
 */
class MainActivity : ComponentActivity() {

    private val respinti = mutableStateOf(emptyList<Respinto>())
    private val whitelist = mutableStateOf(emptyList<NumeroTelefono>())
    private val messaggi = mutableStateOf(emptyList<Messaggio>())
    private val ruoloChiamate = mutableStateOf(false)
    private val rubrica = mutableStateOf(false)
    private val ruoloSms = mutableStateOf(false)
    private val permessoSms = mutableStateOf(false)
    private val permessoNotifiche = mutableStateOf(true)
    private val tettoRaggiunto = mutableStateOf(false)
    private val impostazioni by lazy { Impostazioni(this) }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        aggiorna()
        setContent {
            MaterialTheme {
                Surface(modifier = Modifier.fillMaxSize()) {
                    if (passoOnboarding() == Passo.Fatto) {
                        Principale(
                            respinti = respinti.value,
                            whitelist = whitelist.value,
                            messaggi = messaggi.value,
                            tettoRaggiunto = tettoRaggiunto.value,
                            impostazioni = impostazioni,
                            onSblocca = ::sblocca,
                            onRimuovi = ::rimuoviDallaWhitelist,
                            onRispondi = ::rispondi,
                        )
                    } else {
                        Onboarding(
                            passo = passoOnboarding(),
                            onChiediRuoloChiamate = ::chiediRuoloChiamate,
                            onChiediRubrica = ::chiediRubrica,
                            onChiediRuoloSms = ::chiediRuoloSms,
                            onChiediPermessoSms = ::chiediPermessoSms,
                            onChiediNotifiche = ::chiediNotifiche,
                        )
                    }
                }
            }
        }
    }

    override fun onResume() {
        super.onResume()
        aggiorna()
    }

    private fun aggiorna() {
        respinti.value = ArchivioRespinti(this).leggi().elenco
        whitelist.value = ArchivioWhitelist(this).leggi().sortedBy { it.canonico }
        messaggi.value = ArchivioMessaggi(this).leggi()
        ruoloChiamate.value = haRuolo(RoleManager.ROLE_CALL_SCREENING)
        rubrica.value = haPermesso(Manifest.permission.READ_CONTACTS)
        ruoloSms.value = haRuolo(RoleManager.ROLE_SMS)
        permessoSms.value = haPermesso(Manifest.permission.SEND_SMS)
        permessoNotifiche.value =
            !richiedeNotifiche() || haPermesso(Manifest.permission.POST_NOTIFICATIONS)
        tettoRaggiunto.value = eOggi(impostazioni.ultimoTettoRaggiunto)
    }

    private fun sblocca(numero: NumeroTelefono) {
        ArchivioWhitelist(this).aggiungi(numero)
        aggiorna()
    }

    private fun rimuoviDallaWhitelist(numero: NumeroTelefono) {
        ArchivioWhitelist(this).rimuovi(numero)
        aggiorna()
    }

    private fun passoOnboarding(): Passo = when {
        !ruoloChiamate.value -> Passo.Chiamate
        !rubrica.value -> Passo.Rubrica
        !ruoloSms.value -> Passo.Sms
        !permessoSms.value -> Passo.PermessoSms
        !permessoNotifiche.value -> Passo.Notifiche
        else -> Passo.Fatto
    }

    private fun rispondi(numero: NumeroTelefono, testo: String) {
        if (!InvioSms(this).manda(numero, testo)) return

        ArchivioMessaggi(this).registra(
            Messaggio(numero, testo, Instant.now(), inviato = true),
        )
        aggiorna()
    }

    private fun chiediRuoloChiamate() = chiediRuolo(RoleManager.ROLE_CALL_SCREENING)

    private fun chiediRuoloSms() = chiediRuolo(RoleManager.ROLE_SMS)

    private fun chiediRuolo(ruolo: String) {
        val gestoreRuoli = getSystemService(RoleManager::class.java) ?: return
        startActivity(gestoreRuoli.createRequestRoleIntent(ruolo))
    }

    private fun chiediRubrica() =
        ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.READ_CONTACTS), RICHIESTA_RUBRICA)

    private fun chiediPermessoSms() =
        ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.SEND_SMS), RICHIESTA_SMS)

    private fun chiediNotifiche() {
        if (richiedeNotifiche()) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                RICHIESTA_NOTIFICHE,
            )
        }
    }

    private fun haRuolo(ruolo: String): Boolean =
        getSystemService(RoleManager::class.java)?.isRoleHeld(ruolo) == true

    private fun haPermesso(permesso: String): Boolean =
        ContextCompat.checkSelfPermission(this, permesso) == PackageManager.PERMISSION_GRANTED

    private fun richiedeNotifiche(): Boolean = Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU

    private fun eOggi(millisecondi: Long): Boolean =
        millisecondi > 0 &&
            Instant.ofEpochMilli(millisecondi).atZone(ZoneId.systemDefault()).toLocalDate() ==
            java.time.LocalDate.now()

    private companion object {
        const val RICHIESTA_RUBRICA = 1
        const val RICHIESTA_SMS = 2
        const val RICHIESTA_NOTIFICHE = 3
    }
}

@Composable
private fun Onboarding(
    passo: Passo,
    onChiediRuoloChiamate: () -> Unit,
    onChiediRubrica: () -> Unit,
    onChiediRuoloSms: () -> Unit,
    onChiediPermessoSms: () -> Unit,
    onChiediNotifiche: () -> Unit,
) {
    Column(
        modifier = Modifier.fillMaxSize().padding(24.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        Text(
            text = stringResource(R.string.onboarding_titolo),
            style = MaterialTheme.typography.headlineSmall,
        )
        when (passo) {
            Passo.Chiamate -> {
                Text(stringResource(R.string.onboarding_perche_chiamate))
                Button(onClick = onChiediRuoloChiamate) {
                    Text(stringResource(R.string.onboarding_chiedi_ruolo_chiamate))
                }
            }

            Passo.Rubrica -> {
                Text(stringResource(R.string.onboarding_perche_rubrica))
                Button(onClick = onChiediRubrica) {
                    Text(stringResource(R.string.onboarding_chiedi_rubrica))
                }
            }

            Passo.Sms -> {
                Text(stringResource(R.string.onboarding_perche_sms))
                // Il costo si dice prima del pulsante: l'utente decide sapendolo.
                Text(stringResource(R.string.onboarding_costo_sms))
                Button(onClick = onChiediRuoloSms) {
                    Text(stringResource(R.string.onboarding_chiedi_ruolo_sms))
                }
            }

            Passo.PermessoSms -> {
                Text(stringResource(R.string.onboarding_perche_permesso_sms))
                Button(onClick = onChiediPermessoSms) {
                    Text(stringResource(R.string.onboarding_chiedi_permesso_sms))
                }
            }

            Passo.Notifiche -> {
                Text(stringResource(R.string.onboarding_perche_notifiche))
                Button(onClick = onChiediNotifiche) {
                    Text(stringResource(R.string.onboarding_chiedi_notifiche))
                }
            }

            Passo.Fatto -> Unit
        }
    }
}

@Composable
private fun Principale(
    respinti: List<Respinto>,
    whitelist: List<NumeroTelefono>,
    messaggi: List<Messaggio>,
    tettoRaggiunto: Boolean,
    impostazioni: Impostazioni,
    onSblocca: (NumeroTelefono) -> Unit,
    onRimuovi: (NumeroTelefono) -> Unit,
    onRispondi: (NumeroTelefono, String) -> Unit,
) {
    var sezione by remember { mutableStateOf(Sezione.Chiamate) }

    Column(modifier = Modifier.fillMaxSize()) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 8.dp, vertical = 4.dp),
            horizontalArrangement = Arrangement.spacedBy(4.dp),
        ) {
            TextButton(onClick = { sezione = Sezione.Chiamate }) {
                Text(stringResource(R.string.sezione_chiamate))
            }
            TextButton(onClick = { sezione = Sezione.Messaggi }) {
                Text(stringResource(R.string.sezione_messaggi))
            }
            TextButton(onClick = { sezione = Sezione.Impostazioni }) {
                Text(stringResource(R.string.sezione_impostazioni))
            }
        }
        HorizontalDivider()

        if (tettoRaggiunto) {
            Text(
                text = stringResource(R.string.avviso_tetto),
                modifier = Modifier.fillMaxWidth().padding(16.dp),
                style = MaterialTheme.typography.bodyMedium,
            )
        }

        when (sezione) {
            Sezione.Chiamate -> StoricoEWhitelist(respinti, whitelist, messaggi, onSblocca, onRimuovi)
            Sezione.Messaggi -> Messaggi(messaggi, onRispondi)
            Sezione.Impostazioni -> SchermataImpostazioni(impostazioni)
        }
    }
}

@Composable
private fun StoricoEWhitelist(
    respinti: List<Respinto>,
    whitelist: List<NumeroTelefono>,
    messaggi: List<Messaggio>,
    onSblocca: (NumeroTelefono) -> Unit,
    onRimuovi: (NumeroTelefono) -> Unit,
) {
    val risposte = risposteDeiRespinti(respinti, messaggi)

    LazyColumn(
        modifier = Modifier.fillMaxSize().padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        item {
            Text(
                text = stringResource(R.string.storico_titolo),
                style = MaterialTheme.typography.headlineSmall,
            )
        }
        if (respinti.isEmpty()) {
            item { Text(stringResource(R.string.storico_vuoto)) }
        } else {
            items(respinti) { respinto ->
                Column {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(testoRespinto(respinto), modifier = Modifier.weight(1f))
                        Button(onClick = { onSblocca(respinto.numero) }) {
                            Text(stringResource(R.string.storico_sblocca))
                        }
                    }
                    risposte[respinto.numero]?.let { risposta ->
                        // La risposta è il modo per sbloccare: un tocco e il
                        // numero passa dalle chiamate successive.
                        Text(
                            text = stringResource(R.string.storico_risposta, risposta.testo),
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable { onSblocca(respinto.numero) }
                                .padding(top = 4.dp),
                            color = MaterialTheme.colorScheme.primary,
                            style = MaterialTheme.typography.bodyMedium,
                        )
                    }
                }
            }
        }

        item {
            Text(
                text = stringResource(R.string.whitelist_titolo),
                style = MaterialTheme.typography.headlineSmall,
                modifier = Modifier.padding(top = 16.dp),
            )
        }
        if (whitelist.isEmpty()) {
            item { Text(stringResource(R.string.whitelist_vuoto)) }
        } else {
            items(whitelist) { numero ->
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(numero.toString(), modifier = Modifier.weight(1f))
                    Button(onClick = { onRimuovi(numero) }) {
                        Text(stringResource(R.string.whitelist_rimuovi))
                    }
                }
            }
        }
    }
}

@Composable
private fun Messaggi(messaggi: List<Messaggio>, onRispondi: (NumeroTelefono, String) -> Unit) {
    if (messaggi.isEmpty()) {
        Text(
            text = stringResource(R.string.messaggi_vuoto),
            modifier = Modifier.padding(16.dp),
        )
        return
    }

    val conversazioni = conversazioniDi(messaggi)
    var numeroAperto by remember { mutableStateOf<NumeroTelefono?>(null) }
    val aperto = numeroAperto
    if (aperto == null) {
        LazyColumn(modifier = Modifier.fillMaxSize()) {
            items(conversazioni) { conversazione ->
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable { numeroAperto = conversazione.numero }
                        .padding(16.dp),
                ) {
                    Text(
                        text = conversazione.numero.canonico,
                        style = MaterialTheme.typography.titleMedium,
                    )
                    Text(
                        text = conversazione.messaggi.last().testo,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                        style = MaterialTheme.typography.bodyMedium,
                    )
                }
            }
        }
    } else {
        ConversazioneAperta(
            numero = aperto,
            messaggi = conversazioni.first { it.numero == aperto }.messaggi,
            onRispondi = onRispondi,
            onIndietro = { numeroAperto = null },
        )
    }
}

@Composable
private fun ConversazioneAperta(
    numero: NumeroTelefono,
    messaggi: List<Messaggio>,
    onRispondi: (NumeroTelefono, String) -> Unit,
    onIndietro: () -> Unit,
) {
    var risposta by remember(numero) { mutableStateOf("") }

    Column(modifier = Modifier.fillMaxSize()) {
        TextButton(onClick = onIndietro) { Text(stringResource(R.string.messaggi_indietro)) }
        Text(
            text = numero.canonico,
            modifier = Modifier.padding(horizontal = 16.dp),
            style = MaterialTheme.typography.titleMedium,
        )
        LazyColumn(modifier = Modifier.weight(1f).fillMaxWidth()) {
            items(messaggi) { messaggio ->
                Column(modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 4.dp)) {
                    Text(
                        text = if (messaggio.inviato) {
                            stringResource(R.string.messaggi_tu)
                        } else {
                            numero.canonico
                        },
                        style = MaterialTheme.typography.labelSmall,
                    )
                    Text(messaggio.testo)
                }
            }
        }
        Row(
            modifier = Modifier.fillMaxWidth().padding(8.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            OutlinedTextField(
                value = risposta,
                onValueChange = { risposta = it },
                modifier = Modifier.weight(1f),
                placeholder = { Text(stringResource(R.string.messaggi_rispondi)) },
            )
            Button(
                onClick = {
                    if (risposta.isNotBlank()) {
                        onRispondi(numero, risposta)
                        risposta = ""
                    }
                },
            ) { Text(stringResource(R.string.messaggi_invia)) }
        }
    }
}

@Composable
private fun SchermataImpostazioni(impostazioni: Impostazioni) {
    var testo by remember { mutableStateOf(impostazioni.testoSms) }
    var tetto by remember { mutableStateOf(impostazioni.tettoGiornaliero.toString()) }

    Column(
        modifier = Modifier.fillMaxSize().padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        Text(
            text = stringResource(R.string.impostazioni_titolo),
            style = MaterialTheme.typography.headlineSmall,
        )
        OutlinedTextField(
            value = testo,
            onValueChange = {
                testo = it
                impostazioni.testoSms = it
            },
            modifier = Modifier.fillMaxWidth(),
            label = { Text(stringResource(R.string.impostazioni_testo)) },
            minLines = 3,
        )
        OutlinedTextField(
            value = tetto,
            onValueChange = { nuovo ->
                if (nuovo.all { it.isDigit() }) {
                    tetto = nuovo
                    nuovo.toIntOrNull()?.let { impostazioni.tettoGiornaliero = it }
                }
            },
            modifier = Modifier.fillMaxWidth(),
            label = { Text(stringResource(R.string.impostazioni_tetto)) },
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
        )
    }
}

private val FORMATO_QUANDO: DateTimeFormatter = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm")

private fun testoRespinto(respinto: Respinto): String =
    "${respinto.numero} · ${FORMATO_QUANDO.format(respinto.quando.atZone(ZoneId.systemDefault()))}"
