package it.spamsaver

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier

/**
 * L'unica schermata del primo ticket: vuota.
 *
 * Non chiede permessi, non chiede ruoli di sistema e non tocca la rete. Le
 * schermate vere (storico dei respinti, whitelist, conversazioni, impostazioni)
 * arrivano con i ticket successivi.
 */
class MainActivity : ComponentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent { SchermataVuota() }
    }
}

@Composable
private fun SchermataVuota() {
    Surface(modifier = Modifier.fillMaxSize()) {
        // Intenzionalmente vuota.
    }
}
