package com.noop.ui.forge

import org.junit.Assert.assertEquals
import org.junit.Test

class WoopReferenceColorsTest {
    @Test fun stressLabelBandsMatchTheirMeaning() {
        assertEquals(WoopReferenceColors.stressLow, WoopReferenceColors.stress(0.5))
        assertEquals(WoopReferenceColors.healthGood, WoopReferenceColors.stress(1.2))
        assertEquals(WoopReferenceColors.stressHigh, WoopReferenceColors.stress(2.5))
    }
    @Test fun recoveryGoodIsNeonGreenAndDoesNotInterpolateIntoLime() {
        assertEquals(WoopReferenceColors.recoveryGood, WoopReferenceColors.recovery(81.0))
        assertEquals(WoopReferenceColors.recoveryWarning, WoopReferenceColors.recovery(50.0))
        assertEquals(WoopReferenceColors.recoveryLow, WoopReferenceColors.recovery(27.0))
    }
}
