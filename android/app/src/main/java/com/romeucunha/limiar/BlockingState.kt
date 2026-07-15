package com.romeucunha.limiar

import android.content.Context
import java.util.Calendar

/// Estado persistente do protótipo: apps bloqueados, hora de início do ciclo e
/// a travessia do dia. Espelha a semântica do iOS (dayKey ancorado na hora do
/// ciclo, não à meia-noite): antes da hora de início, o "dia" ainda é o ciclo
/// anterior.
object BlockingState {
    private const val PREFS = "limiar_blocking"
    private const val KEY_PACKAGES = "blocked_packages"
    private const val KEY_START_HOUR = "start_hour"
    private const val KEY_START_MINUTE = "start_minute"
    private const val KEY_DONE_DAY = "travessia_done_day"
    private const val KEY_ENABLED = "blocking_enabled"

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun blockedPackages(context: Context): Set<String> =
        prefs(context).getStringSet(KEY_PACKAGES, emptySet()) ?: emptySet()

    fun setBlockedPackages(context: Context, packages: Set<String>) =
        prefs(context).edit().putStringSet(KEY_PACKAGES, packages).apply()

    fun startHour(context: Context): Int = prefs(context).getInt(KEY_START_HOUR, 5)
    fun startMinute(context: Context): Int = prefs(context).getInt(KEY_START_MINUTE, 0)

    fun setStart(context: Context, hour: Int, minute: Int) =
        prefs(context).edit().putInt(KEY_START_HOUR, hour).putInt(KEY_START_MINUTE, minute).apply()

    fun isEnabled(context: Context): Boolean = prefs(context).getBoolean(KEY_ENABLED, false)
    fun setEnabled(context: Context, enabled: Boolean) =
        prefs(context).edit().putBoolean(KEY_ENABLED, enabled).apply()

    /// Chave do ciclo corrente: o dia "vira" na hora de início, como no iOS.
    fun currentCycleKey(context: Context, now: Calendar = Calendar.getInstance()): String {
        val cycle = now.clone() as Calendar
        cycle.set(Calendar.HOUR_OF_DAY, startHour(context))
        cycle.set(Calendar.MINUTE, startMinute(context))
        cycle.set(Calendar.SECOND, 0)
        cycle.set(Calendar.MILLISECOND, 0)
        if (now.before(cycle)) cycle.add(Calendar.DAY_OF_YEAR, -1)
        return "%04d-%02d-%02d".format(
            cycle.get(Calendar.YEAR), cycle.get(Calendar.MONTH) + 1, cycle.get(Calendar.DAY_OF_MONTH)
        )
    }

    fun markTravessiaDone(context: Context) =
        prefs(context).edit().putString(KEY_DONE_DAY, currentCycleKey(context)).apply()

    fun isTravessiaDone(context: Context): Boolean =
        prefs(context).getString(KEY_DONE_DAY, null) == currentCycleKey(context)

    /// Bloqueio ativo = recurso ligado, ciclo já começou hoje e travessia pendente.
    fun shouldBlockNow(context: Context): Boolean =
        isEnabled(context) && !isTravessiaDone(context) && blockedPackages(context).isNotEmpty()

    /// Próximo início de ciclo (para o alarme exato).
    fun nextCycleStartMillis(context: Context): Long {
        val now = Calendar.getInstance()
        val next = now.clone() as Calendar
        next.set(Calendar.HOUR_OF_DAY, startHour(context))
        next.set(Calendar.MINUTE, startMinute(context))
        next.set(Calendar.SECOND, 0)
        next.set(Calendar.MILLISECOND, 0)
        if (!next.after(now)) next.add(Calendar.DAY_OF_YEAR, 1)
        return next.timeInMillis
    }
}
