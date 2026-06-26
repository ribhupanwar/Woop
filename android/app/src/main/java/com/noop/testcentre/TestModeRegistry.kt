package com.noop.testcentre

/** Whether a guided capture counts nights (Sleep) or days (Battery). */
enum class CaptureUnit { NIGHTS, DAYS }

/** How a mode captures: a plain toggle, or a guided "wear it N nights/days" window. Twin of the Swift
 *  CaptureKind. */
sealed class CaptureKind {
    object Toggle : CaptureKind()
    data class Guided(val unit: CaptureUnit, val defaultCount: Int) : CaptureKind()
}

/** Display priority on the Test Centre screen. */
enum class TestPriority { HIGH, MED, LOW }

/** One questionnaire prompt declared by a mode. Answers stored in meta.json under [id]. */
data class Question(
    val id: String,
    val prompt: String,
    val kind: Kind,
    val choices: List<String> = emptyList(),
) {
    enum class Kind { YES_NO, TEXT, TIME, CHOICE }
}

/** A test mode is DATA, not code (spec section 3.1). The screen, export and questionnaire all render
 *  from this. Twin of the Swift TestMode, byte-aligned by a parity test. */
data class TestMode(
    val domain: TestDomain,
    val title: String,
    val blurb: String,
    val icon: String,                 // drawable id on Android; SF Symbol on Apple
    val priority: TestPriority,
    val captures: List<String>,
    val questionnaire: List<Question>,
    val liveReadout: List<String>,
    val capture: CaptureKind,
    val includesScreenshot: Boolean,
    val requires5MG: Boolean,
) {
    val id: String get() = domain.id
}

/** The single source the Test Centre IA iterates. Order is priority order. Twin of the Swift
 *  TestModeRegistry; same ids/titles/captures, verified by [TestModeRegistryParityTest]. */
object TestModeRegistry {

    val all: List<TestMode> = listOf(sleep(), battery())

    fun mode(d: TestDomain): TestMode? = all.firstOrNull { it.domain == d }

    private fun sleep() = TestMode(
        domain = TestDomain.SLEEP, title = "Sleep & Rest",
        blurb = "Wear it a few nights so we can see which gate kept or dropped each sleep run.",
        icon = "ic_bed", priority = TestPriority.HIGH,
        captures = listOf("gateTrace", "gravityCoverage", "hrDensity", "wristOff", "perEpochFeatures",
            "hypnogramV1V2", "ppgOnlyNight", "skinTempDsp", "restSubScores"),
        questionnaire = listOf(
            Question("sleepTimes", "Your actual sleep, wake and out-of-bed times?", Question.Kind.TEXT),
            Question("awakeStill", "Any awake-but-still windows in bed?", Question.Kind.TEXT),
            Question("naps", "Any naps?", Question.Kind.TEXT),
            Question("shiftWork", "Shift work or an unusual schedule?", Question.Kind.YES_NO),
            Question("chargeTiming", "When did you charge the strap?", Question.Kind.TEXT),
            Question("healthSleep", "Is Apple Health / Health Connect also feeding sleep?", Question.Kind.YES_NO),
        ),
        liveReadout = listOf("hrDensityNow", "gravityCoverageNow", "lastNightGateFired"),
        capture = CaptureKind.Guided(CaptureUnit.NIGHTS, 3),
        includesScreenshot = false, requires5MG = false,
    )

    private fun battery() = TestMode(
        domain = TestDomain.BATTERY, title = "Battery & Charging",
        blurb = "Wear it a few days so we can fit your real discharge slope.",
        icon = "ic_battery", priority = TestPriority.MED,
        captures = listOf("socSeries", "chargeSteps", "offWristGaps", "dischargeRun", "fittedSlope",
            "sourceMeasuredVsRated", "batteryGates"),
        questionnaire = listOf(
            Question("whoopAppInstalled", "Is the official WHOOP app installed?", Question.Kind.YES_NO),
            Question("otherPhonePaired", "Is another phone paired to the strap?", Question.Kind.YES_NO),
            Question("chargedInWindow", "Did you charge during the capture?", Question.Kind.YES_NO),
            Question("batterySaverApps", "Any battery-saver apps running?", Question.Kind.TEXT),
        ),
        liveReadout = listOf("currentSoc", "estimateDaysLeft", "slopeSource"),
        capture = CaptureKind.Guided(CaptureUnit.DAYS, 3),
        includesScreenshot = false, requires5MG = false,
    )
}
