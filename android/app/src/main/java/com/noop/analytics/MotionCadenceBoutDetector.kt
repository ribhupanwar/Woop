package com.noop.analytics

/// One non-overlapping minute summarized from a 100 Hz WHOOP 5.0 IMU window.
data class MotionCadenceMinute(
    val startTs: Int,
    val cadenceHz: Double?,
    val rhythmStrength: Double,
    val sampleCount: Int,
    val averageBpm: Int? = null,
)

object MotionCadenceBoutDetector {
    const val minimumDurationMinutes = 10
    const val minimumQualifyingShare = 0.8
    const val maximumGapMinutes = 2
    const val minimumCadenceHz = 1.2
    const val maximumCadenceHz = 3.5
    const val minimumRhythmStrength = 0.20
    const val minimumSamplesPerMinute = 3_000

    enum class Kind { WALK, RUN }
    data class Candidate(
        val startTs: Int, val endTs: Int, val kind: Kind,
        val medianCadenceHz: Double, val meanRhythmStrength: Double,
        val averageBpm: Int?, val hrElevationBpm: Int?, val durationMinutes: Int,
    )

    /// HR is supporting context only; low or missing HR never vetoes a cadence-confirmed bout.
    fun detect(input: List<MotionCadenceMinute>, restingBpm: Int? = null): List<Candidate> {
        val rows = input.sortedBy { it.startTs }
        fun qualifies(row: MotionCadenceMinute) =
            row.sampleCount >= minimumSamplesPerMinute &&
                row.rhythmStrength >= minimumRhythmStrength &&
                (row.cadenceHz?.let { it in minimumCadenceHz..maximumCadenceHz } ?: false)

        val out = mutableListOf<Candidate>()
        var i = 0
        while (i < rows.size) {
            if (!qualifies(rows[i])) { i++; continue }
            val start = i
            var lastGood = i
            var good = 1
            var gap = 0
            var j = i + 1
            while (j < rows.size) {
                if (rows[j].startTs - rows[j - 1].startTs > 60 * (maximumGapMinutes + 1)) break
                if (qualifies(rows[j])) { good++; lastGood = j; gap = 0 }
                else { gap++; if (gap > maximumGapMinutes) break }
                j++
            }
            val spanMinutes = (rows[lastGood].startTs - rows[start].startTs) / 60 + 1
            if (spanMinutes >= minimumDurationMinutes && good.toDouble() / spanMinutes >= minimumQualifyingShare) {
                val bout = rows.subList(start, lastGood + 1).filter(::qualifies)
                val cadence = bout.mapNotNull { it.cadenceHz }.sorted()
                val median = cadence[cadence.size / 2]
                val strengths = bout.map { it.rhythmStrength }
                val hrs = bout.mapNotNull { it.averageBpm }
                val avgHr = if (hrs.isEmpty()) null else (hrs.average()).toInt()
                out += Candidate(
                    rows[start].startTs, rows[lastGood].startTs + 60,
                    if (median >= 2.5) Kind.RUN else Kind.WALK,
                    median, strengths.average(), avgHr,
                    if (avgHr != null && restingBpm != null) avgHr - restingBpm else null,
                    spanMinutes,
                )
            }
            i = maxOf(i + 1, lastGood + 1)
        }
        return out
    }
}
