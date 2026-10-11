package com.callguard.native

/**
 * SU-DOM-01-01 lato nativo: normalizzazione + visibilità + dialability.
 * Totale, mai throw: non parsabile -> null (anonimo-pass downstream).
 */
object PhoneNumbers {
    private val separators = setOf(' ', '-', '.', '(', ')', '/')
    private val dialable = Regex("""^\+?[0-9]{6,15}$""")
    private val shortCode = Regex("""^[0-9]{3,6}$""")
    private val alpha = Regex("""^[A-Za-z][A-Za-z0-9]*$""")

    fun normalizeOrNull(raw: String?): String? {
        if (raw == null) return null
        val trimmed = raw.trim()
        if (trimmed.isEmpty()) return null
        val stripped = buildString {
            for (c in trimmed) if (c !in separators) append(c)
        }
        if (stripped.isEmpty()) return null
        if (alpha.matches(stripped)) return stripped
        if (shortCode.matches(stripped)) return stripped
        var s = stripped
        if (s.startsWith("00")) s = "+" + s.substring(2)
        return s
    }

    fun isSmsDialable(normalized: String): Boolean {
        if (alpha.matches(normalized)) return false
        if (shortCode.matches(normalized)) return false
        return dialable.matches(normalized)
    }
}
