package com.noop.ui.forge

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.noop.ui.AppViewModel

/** Health landing page keeps existing real-data destinations and their edit/consent flows. */
@Composable
internal fun WoopHealthScreen(padding: PaddingValues, viewModel: AppViewModel) {
    val more = rememberMoreNavigator()
    Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(padding).padding(16.dp),
           verticalArrangement = Arrangement.spacedBy(16.dp)) {
        Text("Health", style = Forge.type.title1, color = Forge.colors.text)
        listOf("Healthspan · Age & Pace of Aging" to MoreDest.AgeLess,
               "Health Monitor · Live HR & vitals" to MoreDest.Health,
               "Stress Monitor" to MoreDest.Stress,
               "ECG · WHOOP MG" to MoreDest.Ecg,
               "Health Records · Measured blood pressure" to MoreDest.Biomarkers,
               "Training load" to MoreDest.TrainingLoad).forEach { (label, destination) ->
            ForgeCard(Modifier.fillMaxWidth().clickable { more.push(MoreRoute.Dest(destination)) }, radius = 13.dp) {
                Text(label, style = Forge.type.headline, color = Forge.colors.text,
                     modifier = Modifier.fillMaxWidth().padding(vertical = 14.dp))
            }
        }
    }
    MoreOverlay(more, viewModel, onOpenSettings = { more.push(MoreRoute.Dest(MoreDest.Settings)) })
}
