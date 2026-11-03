package com.noop.analytics

import org.junit.Assert.*
import org.junit.Test

class MotionCadenceBoutDetectorTest {
    private fun minute(i: Int, cadence: Double? = 1.8, strength: Double = 0.55,
                       samples: Int = 6_000, bpm: Int? = 68) =
        MotionCadenceMinute(1_000_000 + i * 60, cadence, strength, samples, bpm)

    @Test fun tenMinuteEasyWalkSurvivesLowHeartRate() {
        val result = MotionCadenceBoutDetector.detect((0 until 10).map { minute(it) }, 65)
        assertEquals(1, result.size)
        assertEquals(MotionCadenceBoutDetector.Kind.WALK, result[0].kind)
        assertEquals(3, result[0].hrElevationBpm)
        assertEquals(10, result[0].durationMinutes)
    }

    @Test fun nineMinutesDoesNotTrigger() {
        assertTrue(MotionCadenceBoutDetector.detect((0 until 9).map { minute(it) }).isEmpty())
    }

    @Test fun weakRhythmAndSparseSamplesDoNotTrigger() {
        assertTrue(MotionCadenceBoutDetector.detect((0 until 12).map { minute(it, strength = 0.1) }).isEmpty())
        assertTrue(MotionCadenceBoutDetector.detect((0 until 12).map { minute(it, samples = 500) }).isEmpty())
    }

    @Test fun twoMinuteGapIsToleratedButThreeMinuteGapSplits() {
        val tolerated = (0 until 12).map { if (it in 4..5) minute(it, cadence = null) else minute(it) }
        assertEquals(1, MotionCadenceBoutDetector.detect(tolerated).size)
        val split = (0 until 15).map { if (it in 4..6) minute(it, cadence = null) else minute(it) }
        assertTrue(MotionCadenceBoutDetector.detect(split).isEmpty())
    }

    @Test fun highCadenceIsRunAndHRCanBeMissing() {
        val rows = (0 until 12).map { minute(it, cadence = 2.8, bpm = null) }
        assertEquals(MotionCadenceBoutDetector.Kind.RUN, MotionCadenceBoutDetector.detect(rows).first().kind)
    }
}
