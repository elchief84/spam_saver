package it.spamsaver

import android.app.role.RoleManager
import android.content.ActivityNotFoundException
import android.content.Context
import it.spamsaver.dominio.AdattatoreRuoli

/**
 * L'[AdattatoreRuoli] di sistema: parla con `RoleManager`.
 *
 * Se il telefono non conosce il ruolo lo dice; se apre la richiesta riferisce se
 * l'attività c'è davvero; al ritorno dice se il ruolo è stato concesso. Non fa
 * cadere l'app quando `RoleManager` manca o quando nessuna attività raccoglie la
 * richiesta: risponde di no, e l'onboarding mostra il messaggio del caso.
 */
class AdattatoreRuoliDiSistema(
    private val contesto: Context,
    private val ruolo: String,
) : AdattatoreRuoli {

    override fun ruoloDisponibile(): Boolean =
        contesto.getSystemService(RoleManager::class.java)?.isRoleAvailable(ruolo) == true

    override fun apriRichiesta(): Boolean {
        val gestoreRuoli = contesto.getSystemService(RoleManager::class.java) ?: return false
        return try {
            contesto.startActivity(gestoreRuoli.createRequestRoleIntent(ruolo))
            true
        } catch (e: ActivityNotFoundException) {
            false
        }
    }

    override fun ruoloOttenuto(): Boolean =
        contesto.getSystemService(RoleManager::class.java)?.isRoleHeld(ruolo) == true
}
