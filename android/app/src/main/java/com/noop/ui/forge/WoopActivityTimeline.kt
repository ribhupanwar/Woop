package com.noop.ui.forge

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.noop.core.CoreRead
import com.noop.ui.AppViewModel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.time.*
import java.time.format.DateTimeFormatter

private data class TimelineEntry(val start: Long, val end: Long, val title: String, val reading: String, val sleep: Boolean)

/** Selected-day activities in ascending time order, with actual decoded sleep minutes only. */
@Composable
internal fun WoopActivityTimeline(date: LocalDate, vm: AppViewModel, onActivities: () -> Unit, onStart: () -> Unit) {
    val workouts by vm.workouts.collectAsState()
    val context = androidx.compose.ui.platform.LocalContext.current
    val revision by com.noop.core.CoreShadow.dataRevision.collectAsState()
    LaunchedEffect(revision) { vm.loadWorkouts() }
    val nights by produceState(emptyList<CoreRead.Night>(), date, revision) {
        value = withContext(Dispatchers.IO) {
            CoreRead.open(context)
            val zone = ZoneId.systemDefault()
            CoreRead.nights(date.minusDays(1).atStartOfDay(zone).toEpochSecond(), date.plusDays(1).atStartOfDay(zone).toEpochSecond())
        }
    }
    val zone = ZoneId.systemDefault()
    val entries = remember(workouts, nights, date) {
        val sleep = nights.filter { Instant.ofEpochSecond(it.endTs).atZone(zone).toLocalDate() == date }.map { night ->
            val mins = night.minutes?.filterKeys { it != "wake" }?.values?.sum()?.toInt()
            TimelineEntry(night.startTs, night.endTs, "SLEEP", mins?.let { "%d:%02d".format(it / 60, it % 60) } ?: "—", true)
        }
        val activity = workouts.filter { Instant.ofEpochSecond(it.startTs).atZone(zone).toLocalDate() == date }
            .distinctBy { Triple(it.startTs, it.endTs, it.sport.lowercase()) }.map {
                TimelineEntry(it.startTs, it.endTs, (if (it.sport.equals("detected", true)) "ACTIVITY" else it.sport.uppercase()), it.strain?.let { n -> "%.1f".format(n) } ?: "—", false)
            }
        (sleep + activity).sortedBy { it.start }
    }
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text("My Day", style = Forge.type.title2, color = Forge.colors.text)
        ForgeCard(Modifier.fillMaxWidth(), radius = 13.dp) {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text("TODAY’S ACTIVITIES", style = Forge.type.overline, color = Forge.colors.text)
                if (entries.isEmpty()) Text("Your recorded sleep and activities will appear after sync.", style = Forge.type.caption, color = Forge.colors.textSecondary)
                entries.forEach { row ->
                    Row(Modifier.fillMaxWidth().background(Forge.colors.inset, RoundedCornerShape(10.dp))
                        .clickable(onClick = onActivities).padding(10.dp), verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        Box(Modifier.width(74.dp).height(42.dp).background(if (row.sleep) Forge.colors.rest else Forge.colors.effort, RoundedCornerShape(8.dp)), contentAlignment = Alignment.Center) {
                            Text(row.reading, style = Forge.type.headline, color = Forge.colors.onDark)
                        }
                        Text(row.title, style = Forge.type.overline, color = Forge.colors.text, modifier = Modifier.weight(1f))
                        Column(horizontalAlignment = Alignment.End) {
                            Text(Instant.ofEpochSecond(row.start).atZone(zone).format(DateTimeFormatter.ofPattern("h:mm a")), style = Forge.type.caption, color = Forge.colors.textSecondary)
                            Text(Instant.ofEpochSecond(row.end).atZone(zone).format(DateTimeFormatter.ofPattern("h:mm a")), style = Forge.type.caption, color = Forge.colors.textSecondary)
                        }
                    }
                }
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    Text("+ ADD ACTIVITY", style = Forge.type.overline, color = Forge.colors.text,
                         modifier = Modifier.weight(1f).clickable(onClick = onActivities).padding(vertical = 16.dp))
                    Text("START ACTIVITY", style = Forge.type.overline, color = Forge.colors.text,
                         modifier = Modifier.weight(1f).clickable(onClick = onStart).padding(vertical = 16.dp))
                }
            }
        }
    }
}
