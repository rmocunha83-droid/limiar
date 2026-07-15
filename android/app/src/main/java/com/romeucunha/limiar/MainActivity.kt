package com.romeucunha.limiar

import android.app.AppOpsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Bundle
import android.os.PowerManager
import android.os.Process
import android.provider.Settings
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.romeucunha.limiar.blocking.BlockingScheduler

private val DeepInk = Color(0xFF0A1112)
private val Ivory = Color(0xFFF2EAD9)
private val SoftText = Color(0xFFA9B0AD)
private val Sage = Color(0xFFB3CFB8)
private val WarmGold = Color(0xFFC98D4B)

class MainActivity : ComponentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val openTravessia = intent.getBooleanExtra(EXTRA_OPEN_TRAVESSIA, false)
        setContent { PrototypeScreen(openTravessia) }
    }

    companion object {
        const val EXTRA_OPEN_TRAVESSIA = "open_travessia"
    }
}

@Composable
private fun PrototypeScreen(startInTravessia: Boolean) {
    val context = androidx.compose.ui.platform.LocalContext.current
    var refresh by remember { mutableStateOf(0) }
    var showTravessia by remember { mutableStateOf(startInTravessia) }

    // Releitura simples de estado a cada interação/re-entrada.
    val usageGranted = remember(refresh) { hasUsageAccess(context) }
    val overlayGranted = remember(refresh) { Settings.canDrawOverlays(context) }
    val batteryExempt = remember(refresh) { isBatteryExempt(context) }
    val enabled = remember(refresh) { BlockingState.isEnabled(context) }
    val done = remember(refresh) { BlockingState.isTravessiaDone(context) }
    val blockedCount = remember(refresh) { BlockingState.blockedPackages(context).size }

    MaterialTheme(colorScheme = darkColorScheme(background = DeepInk, surface = DeepInk)) {
        Column(
            Modifier.fillMaxSize().background(DeepInk).padding(22.dp)
        ) {
            Spacer(Modifier.height(34.dp))
            Text("Limiar", color = Ivory, fontSize = 40.sp, fontFamily = FontFamily.Serif)
            Text(
                "Protótipo Fase 0 — prova do bloqueio",
                color = WarmGold, fontSize = 13.sp
            )
            Spacer(Modifier.height(18.dp))

            if (showTravessia) {
                TravessiaScreen(onDone = {
                    BlockingState.markTravessiaDone(context)
                    showTravessia = false
                    refresh++
                })
                return@Column
            }

            LazyColumn(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                item {
                    PermissionCard("1. Acesso de uso", usageGranted,
                        "Necessário para saber qual app está aberto.") {
                        context.startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                    }
                }
                item {
                    PermissionCard("2. Sobrepor a outros apps", overlayGranted,
                        "Necessário para mostrar a tela do Limiar sobre o app bloqueado.") {
                        context.startActivity(
                            Intent(
                                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                Uri.parse("package:${context.packageName}")
                            )
                        )
                    }
                }
                item {
                    PermissionCard("3. Ignorar economia de bateria", batteryExempt,
                        "Evita que o sistema encerre a proteção durante a noite (essencial em Xiaomi/Samsung).") {
                        context.startActivity(
                            Intent(
                                Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                                Uri.parse("package:${context.packageName}")
                            )
                        )
                    }
                }
                item { AppPicker(onChange = { refresh++ }) }
                item {
                    Card(colors = CardDefaults.cardColors(containerColor = Color(0xFF111B1C))) {
                        Column(Modifier.padding(16.dp)) {
                            Text("Ciclo e status", color = WarmGold, fontSize = 13.sp)
                            Spacer(Modifier.height(6.dp))
                            Text(
                                if (done) "Travessia de hoje concluída — apps liberados."
                                else if (enabled) "Bloqueio ativo: $blockedCount app(s) até a travessia."
                                else "Bloqueio desligado.",
                                color = Ivory, fontSize = 15.sp
                            )
                            Spacer(Modifier.height(10.dp))
                            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                                Button(
                                    onClick = {
                                        BlockingState.setEnabled(context, true)
                                        BlockingScheduler.scheduleAll(context)
                                        refresh++
                                    },
                                    enabled = usageGranted && overlayGranted && blockedCount > 0,
                                    colors = ButtonDefaults.buttonColors(
                                        containerColor = Sage, contentColor = DeepInk
                                    )
                                ) { Text("Ativar agora") }
                                OutlinedButton(onClick = {
                                    BlockingState.setEnabled(context, false)
                                    BlockingScheduler.cancelAll(context)
                                    refresh++
                                }) { Text("Desligar", color = SoftText) }
                            }
                            Spacer(Modifier.height(8.dp))
                            TextButton(onClick = { showTravessia = true }) {
                                Text("Abrir travessia simulada", color = Sage)
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun PermissionCard(title: String, granted: Boolean, why: String, onRequest: () -> Unit) {
    Card(colors = CardDefaults.cardColors(containerColor = Color(0xFF111B1C))) {
        Column(Modifier.padding(16.dp)) {
            Text(title + if (granted) "  ✓" else "", color = if (granted) Sage else Ivory, fontSize = 16.sp)
            Text(why, color = SoftText, fontSize = 13.sp)
            if (!granted) {
                Spacer(Modifier.height(8.dp))
                OutlinedButton(onClick = onRequest) { Text("Conceder", color = Sage) }
            }
        }
    }
}

@Composable
private fun AppPicker(onChange: () -> Unit) {
    val context = androidx.compose.ui.platform.LocalContext.current
    val apps = remember {
        val pm = context.packageManager
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        pm.queryIntentActivities(intent, PackageManager.MATCH_ALL)
            .map { it.activityInfo.packageName to it.loadLabel(pm).toString() }
            .distinctBy { it.first }
            .filterNot { it.first == context.packageName }
            .sortedBy { it.second.lowercase() }
    }
    var selected by remember { mutableStateOf(BlockingState.blockedPackages(context)) }
    Card(colors = CardDefaults.cardColors(containerColor = Color(0xFF111B1C))) {
        Column(Modifier.padding(16.dp)) {
            Text("4. Apps que ativam o Limiar", color = WarmGold, fontSize = 13.sp)
            Spacer(Modifier.height(6.dp))
            Column(Modifier.heightIn(max = 260.dp)) {
                LazyColumn {
                    items(apps) { (pkg, label) ->
                        Row(
                            Modifier.fillMaxWidth().padding(vertical = 2.dp),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Text(label, color = Ivory, fontSize = 15.sp, modifier = Modifier.weight(1f))
                            Switch(checked = selected.contains(pkg), onCheckedChange = { checked ->
                                selected = if (checked) selected + pkg else selected - pkg
                                BlockingState.setBlockedPackages(context, selected)
                                onChange()
                            })
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun TravessiaScreen(onDone: () -> Unit) {
    Column(Modifier.fillMaxWidth()) {
        Text("Travessia (simulada)", color = Ivory, fontSize = 26.sp, fontFamily = FontFamily.Serif)
        Spacer(Modifier.height(10.dp))
        Text(
            "Na versão completa, aqui estão os 3 trechos do dia com as explicações. " +
                "Concluir a leitura libera os apps até o próximo ciclo.",
            color = SoftText, fontSize = 15.sp
        )
        Spacer(Modifier.height(18.dp))
        Button(
            onClick = onDone,
            colors = ButtonDefaults.buttonColors(containerColor = Sage, contentColor = DeepInk),
            modifier = Modifier.fillMaxWidth().height(56.dp)
        ) { Text("Li com calma, continuar", fontSize = 17.sp) }
    }
}

private fun hasUsageAccess(context: Context): Boolean {
    val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
    val mode = appOps.unsafeCheckOpNoThrow(
        AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), context.packageName
    )
    return mode == AppOpsManager.MODE_ALLOWED
}

private fun isBatteryExempt(context: Context): Boolean {
    val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
    return pm.isIgnoringBatteryOptimizations(context.packageName)
}
