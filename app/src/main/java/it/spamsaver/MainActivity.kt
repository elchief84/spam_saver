package it.spamsaver

import android.Manifest
import android.app.role.RoleManager
import android.content.pm.PackageManager
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.mutableStateOf
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import it.spamsaver.dominio.Respinto
import java.time.ZoneId
import java.time.format.DateTimeFormatter

/**
 * L'unica schermata dell'app.
 *
 * Se il ruolo di screening delle chiamate o la lettura della rubrica mancano,
 * l'onboarding li chiede spiegando perché servono; quando ci sono, la schermata
 * mostra lo storico dei respinti.
 */
class MainActivity : ComponentActivity() {

    private val respinti = mutableStateOf(emptyList<Respinto>())
    private val onboarding = mutableStateOf(true)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        aggiorna()
        setContent {
            MaterialTheme {
                Surface(modifier = Modifier.fillMaxSize()) {
                    if (onboarding.value) {
                        Onboarding(
                            onChiediRuolo = ::chiediRuolo,
                            onChiediRubrica = ::chiediRubrica,
                        )
                    } else {
                        StoricoDeiRespinti(respinti.value)
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
        onboarding.value = !haRuoloERubrica()
    }

    private fun haRuoloERubrica(): Boolean {
        val ruolo = getSystemService(RoleManager::class.java)
            ?.isRoleHeld(RoleManager.ROLE_CALL_SCREENING) == true
        val rubrica = ContextCompat.checkSelfPermission(this, Manifest.permission.READ_CONTACTS) ==
            PackageManager.PERMISSION_GRANTED
        return ruolo && rubrica
    }

    private fun chiediRuolo() {
        val gestoreRuoli = getSystemService(RoleManager::class.java) ?: return
        startActivity(gestoreRuoli.createRequestRoleIntent(RoleManager.ROLE_CALL_SCREENING))
    }

    private fun chiediRubrica() {
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.READ_CONTACTS),
            RICHIESTA_RUBRICA,
        )
    }

    private companion object {
        const val RICHIESTA_RUBRICA = 1
    }
}

@Composable
private fun Onboarding(onChiediRuolo: () -> Unit, onChiediRubrica: () -> Unit) {
    Column(
        modifier = Modifier.fillMaxSize().padding(24.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        Text(
            text = stringResource(R.string.onboarding_titolo),
            style = MaterialTheme.typography.headlineSmall,
        )
        Text(stringResource(R.string.onboarding_perche))
        Button(onClick = onChiediRuolo) { Text(stringResource(R.string.onboarding_chiedi_ruolo)) }
        Button(onClick = onChiediRubrica) { Text(stringResource(R.string.onboarding_chiedi_rubrica)) }
    }
}

@Composable
private fun StoricoDeiRespinti(respinti: List<Respinto>) {
    Column(
        modifier = Modifier.fillMaxSize().padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Text(
            text = stringResource(R.string.storico_titolo),
            style = MaterialTheme.typography.headlineSmall,
        )
        if (respinti.isEmpty()) {
            Text(stringResource(R.string.storico_vuoto))
        } else {
            LazyColumn(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                items(respinti) { respinto -> Text(testoRespinto(respinto)) }
            }
        }
    }
}

private val FORMATO_QUANDO: DateTimeFormatter = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm")

private fun testoRespinto(respinto: Respinto): String =
    "${respinto.numero} · ${FORMATO_QUANDO.format(respinto.quando.atZone(ZoneId.systemDefault()))}"
