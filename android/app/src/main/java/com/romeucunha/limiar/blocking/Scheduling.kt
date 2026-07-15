package com.romeucunha.limiar.blocking

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import com.romeucunha.limiar.BlockingState
import java.util.concurrent.TimeUnit

/// Três camadas de resiliência contra os "mata-serviços" dos fabricantes
/// (padrões documentados em dontkillmyapp.com):
/// 1. Alarme exato no início do ciclo (acorda mesmo em Doze quando permitido).
/// 2. Watchdog periódico via WorkManager (15 min) religa o serviço se morto.
/// 3. BootReceiver re-agenda tudo após reinício ou atualização do app.
object BlockingScheduler {

    fun scheduleAll(context: Context) {
        if (!BlockingState.isEnabled(context)) return
        scheduleCycleAlarm(context)
        scheduleWatchdog(context)
        BlockingService.start(context)
    }

    fun cancelAll(context: Context) {
        val alarm = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarm.cancel(cyclePendingIntent(context))
        WorkManager.getInstance(context).cancelUniqueWork(WATCHDOG_WORK)
        context.stopService(Intent(context, BlockingService::class.java))
    }

    private fun scheduleCycleAlarm(context: Context) {
        val alarm = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val at = BlockingState.nextCycleStartMillis(context)
        val pending = cyclePendingIntent(context)
        val canExact = alarm.canScheduleExactAlarms()
        if (canExact) {
            alarm.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pending)
        } else {
            // Sem permissão de alarme exato: janela inexata (o watchdog cobre o resto).
            alarm.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pending)
        }
    }

    private fun scheduleWatchdog(context: Context) {
        val request = PeriodicWorkRequestBuilder<WatchdogWorker>(15, TimeUnit.MINUTES).build()
        WorkManager.getInstance(context).enqueueUniquePeriodicWork(
            WATCHDOG_WORK, ExistingPeriodicWorkPolicy.UPDATE, request
        )
    }

    private fun cyclePendingIntent(context: Context): PendingIntent =
        PendingIntent.getBroadcast(
            context, 11,
            Intent(context, CycleAlarmReceiver::class.java),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

    private const val WATCHDOG_WORK = "limiar_watchdog"
}

class CycleAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        // Novo ciclo começou: religa o serviço e agenda o alarme de amanhã.
        BlockingScheduler.scheduleAll(context)
    }
}

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        BlockingScheduler.scheduleAll(context)
    }
}

class WatchdogWorker(context: Context, params: WorkerParameters) : Worker(context, params) {
    override fun doWork(): Result {
        // Religa o serviço caso o fabricante o tenha matado. startForegroundService
        // a partir do WorkManager é permitido enquanto houver cota; se o sistema
        // negar, o próximo alarme de ciclo recupera.
        runCatching { BlockingScheduler.scheduleAll(applicationContext) }
        return Result.success()
    }
}
