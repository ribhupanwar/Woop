package com.noop.ui.forge

import androidx.compose.ui.graphics.Color

/** Central reference swatches: score, health status and stress words have separate semantic roles. */
internal object WoopReferenceColors {
    val sleep = Color(0xFF7BA4BB)
    val strain = Color(0xFF009FE8)
    val recoveryGood = Color(0xFF20F000)
    val recoveryWarning = Color(0xFFFFDE00)
    val recoveryLow = Color(0xFFFF334D)
    val healthGood = Color(0xFF00D6A2)
    val stressLow = Color(0xFF68B4E8)
    val stressHigh = Color(0xFFFFAF00)
    fun recovery(score: Double): Color = when {
        !score.isFinite() || score !in 0.0..100.0 -> Color.Gray
        score < 34 -> recoveryLow
        score < 67 -> recoveryWarning
        else -> recoveryGood
    }
    fun stress(score: Double): Color = when {
        !score.isFinite() || score !in 0.0..3.0 -> Color.Gray
        score < 1 -> stressLow
        score < 2 -> healthGood
        else -> stressHigh
    }
}
