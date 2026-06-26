package com.noop.testcentre

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** Mirror of the Swift TestModeRegistryTests. The ids/titles/captures/capture-kind MUST match the Swift
 *  TestModeRegistry byte-for-byte (spec section 10 parity contract). */
class TestModeRegistryParityTest {

    @Test fun phase1ShipsExactlySleepThenBattery() {
        assertEquals(listOf(TestDomain.SLEEP, TestDomain.BATTERY), TestModeRegistry.all.map { it.domain })
        assertEquals(listOf("sleep", "battery"), TestModeRegistry.all.map { it.id })
    }

    @Test fun lookupByDomain() {
        assertEquals("Sleep & Rest", TestModeRegistry.mode(TestDomain.SLEEP)?.title)
        assertEquals("Battery & Charging", TestModeRegistry.mode(TestDomain.BATTERY)?.title)
        assertNull(TestModeRegistry.mode(TestDomain.STEPS))
    }

    @Test fun sleepCaptureSet() {
        assertEquals(
            listOf("gateTrace", "gravityCoverage", "hrDensity", "wristOff", "perEpochFeatures",
                "hypnogramV1V2", "ppgOnlyNight", "skinTempDsp", "restSubScores"),
            TestModeRegistry.mode(TestDomain.SLEEP)?.captures,
        )
    }

    @Test fun batteryCaptureSetAndReadout() {
        assertEquals(
            listOf("socSeries", "chargeSteps", "offWristGaps", "dischargeRun", "fittedSlope",
                "sourceMeasuredVsRated", "batteryGates"),
            TestModeRegistry.mode(TestDomain.BATTERY)?.captures,
        )
        assertEquals(
            listOf("currentSoc", "estimateDaysLeft", "slopeSource"),
            TestModeRegistry.mode(TestDomain.BATTERY)?.liveReadout,
        )
    }

    @Test fun sleepGuidedThreeNights() {
        val cap = TestModeRegistry.mode(TestDomain.SLEEP)?.capture
        assertTrue(cap is CaptureKind.Guided)
        cap as CaptureKind.Guided
        assertEquals(CaptureUnit.NIGHTS, cap.unit)
        assertEquals(3, cap.defaultCount)
    }

    @Test fun batteryGuidedThreeDays() {
        val cap = TestModeRegistry.mode(TestDomain.BATTERY)?.capture
        assertTrue(cap is CaptureKind.Guided)
        cap as CaptureKind.Guided
        assertEquals(CaptureUnit.DAYS, cap.unit)
        assertEquals(3, cap.defaultCount)
    }

    @Test fun sleepQuestionnaireKeys() {
        assertEquals(
            listOf("sleepTimes", "awakeStill", "naps", "shiftWork", "chargeTiming", "healthSleep"),
            TestModeRegistry.mode(TestDomain.SLEEP)?.questionnaire?.map { it.id },
        )
    }

    @Test fun neitherPhase1ModeRequires5MGOrScreenshot() {
        for (m in TestModeRegistry.all) {
            assertFalse(m.requires5MG)
            assertFalse(m.includesScreenshot)
        }
    }
}
