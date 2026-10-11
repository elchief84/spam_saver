package com.callguard.native

import android.content.Context

/** Stato ruolo/permessi/OS — identity context piattaforma (SDS §5). */
object ProtectionState {
    fun hasRole(context: Context): Boolean {
        return try {
            val roleManager =
                context.getSystemService(Context.ROLE_SERVICE) as android.app.role.RoleManager
            roleManager.isRoleHeld(android.app.role.RoleManager.ROLE_CALL_SCREENING)
        } catch (_: Exception) {
            false
        }
    }

    fun isOsSupported(): Boolean =
        android.os.Build.VERSION.SDK_INT >= 29
}
