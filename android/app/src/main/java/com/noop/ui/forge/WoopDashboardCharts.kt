package com.noop.ui.forge

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.unit.dp
import androidx.compose.ui.platform.LocalContext
import com.noop.core.CoreRead
import com.noop.core.CoreStress
import com.noop.core.CoreShadow
import com.noop.analytics.DaytimeStress
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.time.LocalDate
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter

/** Static charts over committed core reads. Missing days/buckets break the line rather than being filled. */
@Composable
internal fun WoopDashboardCharts(date: LocalDate, onStress: () -> Unit) {
    val context = LocalContext.current
    val revision by CoreShadow.dataRevision.collectAsState()
    val week by produceState<List<CoreRead.Day?>>(emptyList(), date, revision) {
        value = withContext(Dispatchers.IO) { CoreRead.open(context); (6 downTo 0).map { CoreRead.day(date.minusDays(it.toLong()).toString()) } }
    }
    val stress by produceState<DaytimeStress.Result?>(null, date, revision) {
        value = if (date == LocalDate.now()) withContext(Dispatchers.IO) {
            CoreStress.day(com.noop.ui.NoopPrefs.stressPersonalBaseline(context))?.result
        } else null
    }
    val blue = Forge.colors.effort
    val green = WoopReferenceColors.healthGood
    val amber = WoopReferenceColors.stressHigh
    val gray = Forge.colors.textSecondary
    val grid = Forge.colors.divider
    Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
        ForgeCard(Modifier.fillMaxWidth().clickable(onClick = onStress), radius = 13.dp) {
            Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
                Text("STRESS MONITOR", style = Forge.type.overline, color = Forge.colors.text)
                val timeline = stress?.timeline.orEmpty()
                val latest = timeline.lastOrNull { it.level != null }
                if (latest == null) Text("Needs recorded daytime sensor data", style = Forge.type.caption, color = gray)
                else {
                    Text("%.1f · Woop stress estimate".format(latest.level), style = Forge.type.headline, color = WoopReferenceColors.stress(latest.level ?: 0.0))
                    Canvas(Modifier.fillMaxWidth().height(165.dp)) {
                        for (n in 0..3) drawLine(grid, Offset(0f, size.height * n / 3), Offset(size.width, size.height * n / 3))
                        val start = timeline.first().startTs
                        val span = (timeline.last().startTs - start).coerceAtLeast(1)
                        val brush = Brush.verticalGradient(listOf(amber, green, blue))
                        var previous: Offset? = null
                        timeline.forEach { point ->
                            val level = point.level
                            if (level == null || !level.isFinite() || level !in 0.0..3.0) previous = null
                            else {
                                val current = Offset(size.width * (point.startTs - start).toFloat() / span, size.height * (1 - level / 3).toFloat())
                                previous?.let { drawLine(brush, it, current, strokeWidth = 2.dp.toPx()) }
                                drawCircle(brush, radius = 1.5.dp.toPx(), center = current)
                                previous = current
                            }
                        }
                    }
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                        val clock = DateTimeFormatter.ofPattern("h:mm a")
                        Text(Instant.ofEpochSecond(timeline.first().startTs).atZone(ZoneId.systemDefault()).format(clock), style = Forge.type.caption, color = gray)
                        Text(Instant.ofEpochSecond(latest.startTs).atZone(ZoneId.systemDefault()).format(clock), style = Forge.type.caption, color = gray)
                    }
                }
            }
        }
        ForgeCard(Modifier.fillMaxWidth(), radius = 13.dp) {
            Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
                Text("STRAIN & RECOVERY", style = Forge.type.overline, color = Forge.colors.text)
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Column(Modifier.height(190.dp), verticalArrangement = Arrangement.SpaceBetween) {
                        listOf("21", "14", "7", "0").forEach { Text(it, style = Forge.type.caption, color = blue) }
                    }
                    Canvas(Modifier.weight(1f).height(190.dp)) {
                        for (n in 0..3) drawLine(grid, Offset(0f, size.height * n / 3), Offset(size.width, size.height * n / 3))
                        for (recovery in listOf(false, true)) {
                            var previous: Offset? = null
                            week.forEachIndexed { index, day ->
                                val score = if (recovery) day?.charge else day?.effort
                                if (score == null || !score.isFinite() || score !in 0.0..100.0) previous = null
                                else {
                                    val point = Offset(size.width * index / 6f, size.height * (1 - score / 100).toFloat())
                                    previous?.let { drawLine(if (recovery) gray else blue, it, point, strokeWidth = 2.dp.toPx()) }
                                    val color = if (!recovery) blue else WoopReferenceColors.recovery(score)
                                    drawCircle(color, radius = 4.dp.toPx(), center = point)
                                    previous = point
                                }
                            }
                        }
                    }
                    Column(Modifier.height(190.dp), verticalArrangement = Arrangement.SpaceBetween) {
                        listOf("100%", "66%", "33%", "0%").forEach { Text(it, style = Forge.type.caption, color = green) }
                    }
                }
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                    (6 downTo 0).forEach { offset -> Text(date.minusDays(offset.toLong()).format(DateTimeFormatter.ofPattern("EE")), style = Forge.type.caption, color = gray) }
                }
                Text("Blue: Strain 0–21 · Colored dots: Recovery %", style = Forge.type.caption, color = gray)
            }
        }
    }
}
