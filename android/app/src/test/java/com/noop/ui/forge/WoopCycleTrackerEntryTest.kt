package com.noop.ui.forge

import com.noop.analytics.CyclePhaseEngine
import org.junit.Assert.*
import org.junit.Test

class WoopCycleTrackerEntryTest {
    @Test fun missingSensorHistoryKeepsManualTrackerAvailableWithoutPrediction() {
        val result = cycleTrackerDisplayResult(null)
        assertEquals(CyclePhaseEngine.Phase.LEARNING, result.phase)
        assertNull(result.nextPeriodWindow)
        assertNull(result.cycleLengthDays)
        assertNull(result.cycleDayLow)
        assertNull(result.cycleDayHigh)
        assertTrue(result.shiftMarkers.isEmpty())
    }

    @Test fun existingSensorResultIsPreserved() {
        val measured = CyclePhaseEngine.Result(
            CyclePhaseEngine.Phase.UNKNOWN, CyclePhaseEngine.Confidence.BUILDING,
            null, null, null, null, emptyList(), "Insufficient evidence")
        assertSame(measured, cycleTrackerDisplayResult(measured))
    }
}
