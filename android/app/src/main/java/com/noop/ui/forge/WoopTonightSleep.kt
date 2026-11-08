package com.noop.ui.forge

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.noop.core.CoreRead
import com.noop.core.CoreSleepDebt
import com.noop.ui.AppViewModel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.time.ZonedDateTime
import java.time.format.DateTimeFormatter
import kotlin.math.roundToInt

/** Same capped debt-repayment presentation heuristic as the iPhone planner, over the shared ledger. */
internal fun woopSleepTargetMinutes(nights: Int, need: Double?, balance: Double?): Int? {
    if (nights <= 0 || need == null || !need.isFinite() || need !in 1.0..1440.0 || balance == null || !balance.isFinite()) return null
    return need.roundToInt() + (-balance).coerceIn(0.0, 120.0).roundToInt()
}

@Composable
internal fun WoopTonightSleep(vm: AppViewModel, onAlarm: () -> Unit) {
    val context = LocalContext.current
    val wakeMinute by vm.smartAlarmMinutes.collectAsState()
    val day by vm.today.collectAsState()
    val ledger by produceState<CoreSleepDebt.Ledger?>(null, day) {
        value = withContext(Dispatchers.IO) { CoreRead.open(context); CoreSleepDebt.read() }
    }
    val target = woopSleepTargetMinutes(ledger?.nightCount ?: 0, ledger?.needMin, ledger?.balanceMin)
    var planner by remember { mutableStateOf(false) }
    val now = ZonedDateTime.now()
    val todayWake = now.withHour(wakeMinute / 60).withMinute(wakeMinute % 60).withSecond(0).withNano(0)
    val wake = if (todayWake.isAfter(now)) todayWake else todayWake.plusDays(1)
    val bedtime = target?.let { wake.minusMinutes(it.toLong()) }
    val formatter = DateTimeFormatter.ofPattern("h:mm a")
    ForgeCard(Modifier.fillMaxWidth().clickable { planner = true }, radius = 13.dp) {
        Column(verticalArrangement = Arrangement.spacedBy(20.dp)) {
            Text("TONIGHT’S SLEEP", style = Forge.type.overline, color = Forge.colors.text)
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                Column {
                    Text(bedtime?.format(formatter) ?: "—", style = Forge.type.title2, color = Forge.colors.text)
                    Text("RECOMMENDED BEDTIME", style = Forge.type.caption, color = Forge.colors.textSecondary)
                }
                Column(horizontalAlignment = Alignment.End) {
                    Text(wake.format(formatter), style = Forge.type.title2, color = Forge.colors.text)
                    Text("CONFIGURED WAKE TIME", style = Forge.type.caption, color = Forge.colors.textSecondary)
                }
            }
            Text("EDIT SLEEP PLAN & ALARM", style = Forge.type.overline, color = Forge.colors.textSecondary)
        }
    }
    if (planner) ForgeOverlayPage(onDismiss = { planner = false }) {
        SettingsColumn {
            PageTitle("Sleep Planner", onBack = { planner = false })
            Text(if (target != null) "Allow ${target / 60}:${(target % 60).toString().padStart(2, '0')} before your configured wake time." else "Record sleep first for a debt-based recommendation.",
                 style = Forge.type.title2, color = Forge.colors.text)
            Text("Woop estimate using your nap-credited debt ledger, with up to two hours repayment tonight. Time in bed does not guarantee sleep or a consistency score.",
                 style = Forge.type.body, color = Forge.colors.textSecondary)
            Text("EDIT ALARM", style = Forge.type.headline, color = Forge.colors.accent,
                 modifier = Modifier.fillMaxWidth().clickable { planner = false; onAlarm() }.padding(vertical = 20.dp))
        }
    }
}
