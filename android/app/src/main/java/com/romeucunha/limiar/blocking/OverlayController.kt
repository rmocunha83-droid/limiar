package com.romeucunha.limiar.blocking

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.view.Gravity
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import com.romeucunha.limiar.MainActivity

/// Overlay em tela cheia com a identidade do Limiar (fundo escuro, serif,
/// verde-sálvia). View clássica de propósito: overlays via WindowManager não
/// têm lifecycle de Compose e a simplicidade aqui é robustez.
class OverlayController(private val context: Context) {

    private var view: LinearLayout? = null
    private val windowManager: WindowManager
        get() = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager

    fun show() {
        if (view != null) return
        val container = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(Color.parseColor("#0A1112"))
            setPadding(64, 0, 64, 0)
        }
        container.addView(TextView(context).apply {
            text = "Limiar"
            textSize = 40f
            setTextColor(Color.parseColor("#F2EAD9"))
            typeface = Typeface.SERIF
            gravity = Gravity.CENTER
        })
        container.addView(TextView(context).apply {
            text = "\nSua manhã começa pela Palavra.\nTrês trechos esperam por você antes deste app.\n"
            textSize = 17f
            setTextColor(Color.parseColor("#A9B0AD"))
            gravity = Gravity.CENTER
        })
        container.addView(Button(context).apply {
            text = "Fazer minha travessia"
            textSize = 17f
            setTextColor(Color.parseColor("#0A1112"))
            setBackgroundColor(Color.parseColor("#B3CFB8"))
            setPadding(48, 28, 48, 28)
            setOnClickListener {
                context.startActivity(
                    Intent(context, MainActivity::class.java).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        putExtra(MainActivity.EXTRA_OPEN_TRAVESSIA, true)
                    }
                )
            }
        })
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.OPAQUE
        )
        runCatching {
            windowManager.addView(container, params)
            view = container
        }
    }

    fun hide() {
        val current = view ?: return
        runCatching { windowManager.removeView(current) }
        view = null
    }
}
