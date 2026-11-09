package com.noop.ui.forge

import org.junit.Assert.*
import org.junit.Test

class WoopSleepTargetTest {
    @Test fun missingOrInvalidHistoryHasNoRecommendation() {
        assertNull(woopSleepTargetMinutes(0, 480.0, 0.0))
        assertNull(woopSleepTargetMinutes(1, Double.NaN, 0.0))
        assertNull(woopSleepTargetMinutes(1, 480.0, Double.POSITIVE_INFINITY))
        assertNull(woopSleepTargetMinutes(1, null, 0.0))
    }
    @Test fun debtRepaymentMatchesIphonePlanningBounds() {
        assertEquals(525, woopSleepTargetMinutes(1, 480.0, -45.0))
        assertEquals(600, woopSleepTargetMinutes(1, 480.0, -600.0))
        assertEquals(480, woopSleepTargetMinutes(1, 480.0, 60.0))
    }
}
