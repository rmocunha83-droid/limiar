package com.romeucunha.limiar.blocking

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import com.romeucunha.limiar.BlockingState
import com.romeucunha.limiar.MainActivity

/// Serviço em foreground que observa o app em primeiro plano via UsageEvents e
/// exibe o overlay do Limiar quando um app bloqueado abre durante o ciclo.
/// Equivalente Android do shield de FamilyControls do iOS — sem garantia de
/// sistema: a robustez vem do conjunto alarme exato + watchdog + boot receiver.
class BlockingService : Service() {

    private val handler = Handler(Looper.getMainLooper())
    private var overlay: OverlayController? = null
    private var lastForegroundPackage: String? = null

    private val pollTask = object : Runnable {
        override fun run() {
            checkForegroundApp()
            handler.postDelayed(this, POLL_INTERVAL_MS)
        }
    }

    override fun onCreate() {
        super.onCreate()
        overlay = OverlayController(this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startInForeground()
        handler.removeCallbacks(pollTask)
        if (BlockingState.shouldBlockNow(this)) {
            handler.post(pollTask)
        } else {
            // Nada a vigiar agora (travessia feita ou fora do ciclo): o serviço
            // permanece vivo e barato até o próximo alarme de ciclo.
            overlay?.hide()
        }
        return START_STICKY
    }

    private fun checkForegroundApp() {
        if (!BlockingState.shouldBlockNow(this)) {
            overlay?.hide()
            handler.removeCallbacks(pollTask)
            return
        }
        val usage = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val now = System.currentTimeMillis()
        val events = usage.queryEvents(now - LOOKBACK_MS, now)
        val event = UsageEvents.Event()
        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            if (event.eventType == UsageEvents.Event.ACTIVITY_RESUMED) {
                lastForegroundPackage = event.packageName
            }
        }
        val foreground = lastForegroundPackage ?: return
        val blocked = BlockingState.blockedPackages(this)
        when {
            foreground == packageName -> overlay?.hide()
            blocked.contains(foreground) -> overlay?.show()
            else -> overlay?.hide()
        }
    }

    private fun startInForeground() {
        val channelId = "limiar_blocking"
        val manager = getSystemService(NotificationManager::class.java)
        if (manager.getNotificationChannel(channelId) == null) {
            manager.createNotificationChannel(
                NotificationChannel(
                    channelId,
                    "Pausa do Limiar",
                    NotificationManager.IMPORTANCE_MIN
                )
            )
        }
        val openApp = PendingIntent.getActivity(
            this, 0, Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE
        )
        val notification: Notification = Notification.Builder(this, channelId)
            .setContentTitle("Limiar")
            .setContentText("Protegendo sua manhã até a travessia.")
            .setSmallIcon(android.R.drawable.ic_lock_idle_lock)
            .setContentIntent(openApp)
            .setOngoing(true)
            .build()
        if (Build.VERSION.SDK_INT >= 34) {
            startForeground(
                NOTIFICATION_ID, notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    override fun onDestroy() {
        handler.removeCallbacks(pollTask)
        overlay?.hide()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    companion object {
        private const val NOTIFICATION_ID = 7
        private const val POLL_INTERVAL_MS = 800L
        private const val LOOKBACK_MS = 5_000L

        fun start(context: Context) {
            val intent = Intent(context, BlockingService::class.java)
            context.startForegroundService(intent)
        }
    }
}
