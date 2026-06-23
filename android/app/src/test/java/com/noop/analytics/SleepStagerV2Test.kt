package com.noop.analytics

import com.noop.data.GravitySample
import com.noop.data.HrSample
import com.noop.data.RrInterval
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import kotlin.math.PI
import kotlin.math.sin
import kotlin.math.roundToInt

/**
 * Basic coverage for the OPT-IN experimental stager [SleepStagerV2] (V7 Pillar 3b, reimplemented from
 * contributor PR #600), the Android twin of SleepStagerV2Tests.swift. Asserts the drop-in CONTRACT — same
 * [SleepStager.stageSession] signature + return shape, segments that tile [start, end] with canonical stage
 * labels — and that the [SleepStageHealer] V1/V2 switch actually routes to V2 (and defaults to V1, byte for
 * byte). NOT a fidelity claim against any reference (the recipe's own validation is n=1).
 */
class SleepStagerV2Test {

    private val dev = "test"

    /** 2025-06-10 00:00:00 UTC — fixed midnight, as in the other stager tests. */
    private val refMidnight = 1_749_513_600L

    private fun stillGravity(start: Long, durationS: Int): List<GravitySample> =
        (0 until durationS).map { GravitySample(deviceId = dev, ts = start + it, x = 0.0, y = 0.0, z = 1.0) }

    private fun sleepHR(start: Long, durationS: Int, base: Int = 52): List<HrSample> =
        (0 until durationS).map { HrSample(deviceId = dev, ts = start + it, bpm = base + ((it / 60) % 3).toInt()) }

    private fun regularRR(start: Long, durationS: Int): List<RrInterval> =
        (0 until durationS).map { i ->
            val rsa = (40.0 * sin(2.0 * PI * i / 4.0)).roundToInt()  // ~0.25 Hz breathing
            RrInterval(deviceId = dev, ts = start + i, rrMs = 1000 + rsa)
        }

    // ── drop-in contract ─────────────────────────────────────────────────────────────────────────────

    @Test
    fun stagesTileTheWholeSpanContiguously() {
        val start = refMidnight + 3_600L
        val dur = 90 * 60
        val end = start + dur
        val segs = SleepStagerV2.stageSession(
            start = start, end = end,
            grav = stillGravity(start, dur), hr = sleepHR(start, dur), rr = regularRR(start, dur),
            resp = emptyList())

        assertFalse("a covered window must produce at least one segment", segs.isEmpty())
        assertEquals("first segment starts at `start`", start, segs.first().start)
        assertEquals("last segment ends at `end`", end, segs.last().end)
        for (i in 1 until segs.size) {
            assertEquals("segments tile with no gap/overlap", segs[i - 1].end, segs[i].start)
            assertTrue("each segment is non-empty", segs[i].end > segs[i].start)
        }
    }

    @Test
    fun onlyCanonicalStageLabels() {
        val start = refMidnight + 3_600L
        val dur = 80 * 60
        val segs = SleepStagerV2.stageSession(
            start = start, end = start + dur,
            grav = stillGravity(start, dur), hr = sleepHR(start, dur), rr = regularRR(start, dur),
            resp = emptyList())
        val allowed = setOf("wake", "light", "deep", "rem")
        for (s in segs) assertTrue("unexpected stage label ${s.stage}", s.stage in allowed)
    }

    @Test
    fun degenerateInputFallsBackToSingleLightBlock() {
        val start = refMidnight
        val end = start + 3_600L
        val segs = SleepStagerV2.stageSession(
            start = start, end = end,
            grav = listOf(GravitySample(deviceId = dev, ts = start, x = 0.0, y = 0.0, z = 1.0)),
            hr = emptyList(), rr = emptyList(), resp = emptyList())
        assertEquals(1, segs.size)
        assertEquals("light", segs.first().stage)
        assertEquals(start, segs.first().start)
        assertEquals(end, segs.first().end)
    }

    // ── the SleepStageHealer V1/V2 switch ──────────────────────────────────────────────────────────────

    /** The opt-in flag routes the heal's re-stage to V2; default (false) stays on V1, byte-identical. */
    @Test
    fun healerSwitchSelectsV2WhenFlagOn() {
        val start = refMidnight + 3_600L
        val dur = 6 * 60 * 60
        val end = start + dur - 1
        val grav = stillGravity(start, dur)
        val hr = sleepHR(start, dur)
        val rr = regularRR(start, dur)

        val v1 = SleepStageHealer.restageFromSamples(start, end, grav, hr, rr, emptyList())
        val v1Default = SleepStageHealer.restageFromSamples(
            start, end, grav, hr, rr, emptyList(), useExperimentalSleepV2 = false)
        val v2 = SleepStageHealer.restageFromSamples(
            start, end, grav, hr, rr, emptyList(), useExperimentalSleepV2 = true)

        assertNotNull("dense raw must stage on both paths", v1)
        assertNotNull(v2)
        assertEquals("default flag is V1 (byte-identical to the no-flag call)", v1, v1Default)
        assertTrue("V1 output is a segment array", v1!!.trimStart().startsWith("["))
        assertTrue("V2 output is a segment array", v2!!.trimStart().startsWith("["))
    }
}
