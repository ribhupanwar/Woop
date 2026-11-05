import Foundation
import StrandAnalytics
import StrandCore
import WhoopStore
import WhoopProtocol

// Activity-detection reads and writes (fork decision 2026-10-31). The suggestions are what the daily pass
// stored; the answers are wearer input; a confirmed session is a workout row under its own source.
extension Repository {

    /// The stored suggestions of the last two weeks, resolved against the answers, the workouts every source
    /// logged and the spans the old Today card was told to forget.
    func activitySuggestions(settings: ActivitySuggestions.Settings) async -> [ActivitySuggestions.Suggestion] {
        guard let store = await storeHandle() else { return [] }
        let now = Int(Date().timeIntervalSince1970)
        let from = now - (ActivitySuggestions.listDays + 1) * 86_400
        let candidates = (try? await store.activityCandidates(deviceId: deviceId, from: from, to: now + 1)) ?? []
        guard !candidates.isEmpty else { return [] }
        let answers = (try? await store.activitySuggestionAnswers(from: from, to: now + 1)) ?? []
        let workouts = await workoutRows(days: ActivitySuggestions.listDays + 2)
        return ActivitySuggestions.resolve(candidates: candidates, answers: answers, workouts: workouts,
                                           legacyDismissed: legacyAutoDetectDismissedWindows, settings: settings)
    }

    /// One day's suggestions for the logging sheet: the stored ones when there are any, else computed on
    /// the spot from the stored minutes, so the sheet offers them with detection off too. Read only.
    func activitySuggestions(day: Date, hrMax: Int) async -> [ActivitySuggestions.Suggestion] {
        guard let store = await storeHandle() else { return [] }
        let cal = Calendar.current
        let dayStart = Int(cal.startOfDay(for: day).timeIntervalSince1970)
        let dayEnd = min(Int(cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: day))!.timeIntervalSince1970),
                         Int(Date().timeIntervalSince1970))
        guard dayEnd > dayStart else { return [] }
        var rows = (try? await store.activityCandidates(deviceId: deviceId, from: dayStart, to: dayEnd)) ?? []
        if rows.isEmpty {
            rows = ((try? await ActivitySuggestions.dayCandidates(
                store: store, deviceId: deviceId, computedId: deviceId + "-noop", hrMax: hrMax,
                dayStart: dayStart, dayEnd: dayEnd)) ?? [])
                .map { ActivitySuggestions.row($0, deviceId: deviceId) }
        }
        let answers = (try? await store.activitySuggestionAnswers(from: dayStart, to: dayEnd)) ?? []
        let workouts = await workoutRows(days: max(2, Int(Date().timeIntervalSince(day) / 86_400) + 2))
        let all = ActivitySuggestions.resolve(candidates: rows, answers: answers, workouts: workouts,
                                              settings: .init(level: .more, walks: true))
        return ActivitySuggestions.forSheet(all, dayStart: dayStart, dayEnd: dayEnd)
    }

    /// Recomputes the recent suggestions now, as the daily pass would, when detection is switched on.
    func refreshActivitySuggestions(hrMax: Int) async {
        guard ActivitySuggestionCenter.isEnabled else { return }
        guard let store = await storeHandle() else { return }
        _ = try? await ActivitySuggestions.refresh(store: store, deviceId: deviceId, computedId: deviceId + "-noop",
                                                   hrMax: hrMax, now: Int(Date().timeIntervalSince1970))
        await ActivitySuggestionCenter.shared.reload()
    }

    func recordActivityAnswer(_ answer: ActivitySuggestionAnswer) async {
        guard let store = await storeHandle() else { return }
        _ = try? await store.recordActivitySuggestionAnswer(answer)
    }

    /// Writes the confirmed session under `detected-confirmed` (never "manual") and the answer pointing at it.
    func confirmActivitySuggestion(row: WorkoutRow, answer: ActivitySuggestionAnswer) async {
        let confirmed = WorkoutRow(startTs: row.startTs, endTs: row.endTs, sport: row.sport,
                                   source: WorkoutSource.confirmedSuggestionSource, durationS: row.durationS,
                                   energyKcal: row.energyKcal, avgHr: row.avgHr, maxHr: row.maxHr,
                                   strain: row.strain, distanceM: row.distanceM, zonesJSON: row.zonesJSON,
                                   notes: row.notes, steps: row.steps)
        await saveManualWorkout(confirmed)
        var linked = answer
        linked.workout = .init(deviceId: deviceId, startTs: confirmed.startTs, sport: confirmed.sport)
        await recordActivityAnswer(linked)
        await refresh()
    }

    /// Saves a high-confidence strap-classified activity without opening the confirmation sheet.
    /// The answer and workout share the same stable candidate key, making repeated analysis passes idempotent.
    func autoLogActivitySuggestion(_ s: ActivitySuggestions.Suggestion, row: WorkoutRow,
                                   answer: ActivitySuggestionAnswer) async {
        guard let store = await storeHandle() else { return }
        let existing = (try? await store.activitySuggestionAnswers(from: s.start, to: s.end)) ?? []
        guard !existing.contains(where: { $0.track == answer.track && $0.candidateStartTs == s.start }) else { return }
        // If the cadence detector already persisted this same session, link the suggestion answer
        // to it rather than creating a second workout row.
        let recent = await workoutRows(days: ActivitySuggestions.listDays + 2)
        if let detected = recent.first(where: {
            $0.startTs == row.startTs && WorkoutSource.classify($0.source) == .confirmed
                && ($0.notes?.hasPrefix("Automatically detected from WHOOP 5 live motion cadence") ?? false)
        }) {
            var linked = answer
            linked.workout = .init(deviceId: deviceId, startTs: detected.startTs, sport: detected.sport)
            _ = try? await store.recordActivitySuggestionAnswer(linked)
            await refresh()
            return
        }
        let confirmed = WorkoutRow(startTs: row.startTs, endTs: row.endTs, sport: row.sport,
                                   source: WorkoutSource.confirmedSuggestionSource, durationS: row.durationS,
                                   energyKcal: nil, avgHr: row.avgHr, maxHr: row.maxHr,
                                   strain: row.strain, distanceM: row.distanceM, zonesJSON: row.zonesJSON,
                                   notes: "Automatically detected from strap motion + heart-rate data",
                                   steps: row.steps)

        // Do not route this through saveManualWorkout: that path schedules noteLogged() asynchronously.
        // During an auto-detection refresh it could re-enter the resolver before the automatic answer exists,
        // observe the still-open candidate, and attempt to auto-save it a second time. Persist the workout,
        // then its answer, and only then publish a repository refresh.
        do { _ = try await store.upsertWorkouts([confirmed], deviceId: deviceId) }
        catch { return }

        var linked = answer
        linked.workout = .init(deviceId: deviceId, startTs: confirmed.startTs, sport: confirmed.sport)
        _ = try? await store.recordActivitySuggestionAnswer(linked)
        _ = await autoLogMotionDetectedWorkout(
            startTs: confirmed.startTs, endTs: confirmed.endTs, sport: confirmed.sport,
            averageBpm: confirmed.avgHr,
            stepTicksPerStep: ProfileStore.persistedStepTicksPerStep,
            strideLengthM: ProfileStore.persistedStrideLengthM(for: confirmed.sport))
    }

    /// One-time repair for earlier automatic motion rows: their stored HR fallback prevented the
    /// strap's own session-energy buckets from ever being considered by Workouts/Workout Detail.
    /// Only rows created by this detector are touched; manual/imported/entered energy is preserved.
    func clearAutoMotionEnergyFallbacks() async {
        guard let store = await storeHandle() else { return }
        let stale = await workoutRows(days: ActivitySuggestions.listDays + 2).filter {
            WorkoutSource.classify($0.source) == .confirmed
                && (($0.notes?.hasPrefix("Automatically detected from WHOOP 5 live motion cadence") ?? false)
                    || ($0.notes?.hasPrefix("Automatically detected from strap motion + heart-rate data") ?? false))
                && $0.energyKcal != nil
        }
        guard !stale.isEmpty else { return }
        let cleared = stale.map { row in
            WorkoutRow(startTs: row.startTs, endTs: row.endTs, sport: row.sport, source: row.source,
                       durationS: row.durationS, energyKcal: nil, avgHr: row.avgHr, maxHr: row.maxHr,
                       strain: row.strain, distanceM: row.distanceM, zonesJSON: row.zonesJSON,
                       notes: row.notes, steps: row.steps)
        }
        do { _ = try await store.upsertWorkouts(cleared, deviceId: deviceId) }
        catch { return }
        if let earliest = stale.map(\.startTs).min() { scheduleEnergyRefresh(coveringStart: earliest) }
        await refresh()
    }

    /// Persist a cadence-confirmed WHOOP 5 motion bout without a prompt. Repeated detector updates
    /// extend the existing confirmed workout's end time while preserving its stable identity.
    @discardableResult
    func autoLogMotionDetectedWorkout(startTs: Int, endTs: Int, sport: String, averageBpm: Int?,
                                      medianCadenceHz: Double? = nil, distanceM: Double? = nil,
                                      stepTicksPerStep: Double = 1.0,
                                      strideLengthM: Double? = nil) async -> Int? {
        guard endTs > startTs, let store = await storeHandle() else { return nil }
        // One motion bout keeps its identity as the rolling cadence label changes.
        let existing = await workoutRows(days: ActivitySuggestions.listDays + 2).first(where: {
            $0.startTs == startTs
                && WorkoutSource.classify($0.source) == .confirmed
                && (($0.notes?.hasPrefix("Automatically detected from WHOOP 5 live motion cadence") ?? false)
                    || ($0.notes?.hasPrefix("Automatically detected from strap motion + heart-rate data") ?? false))
        })
        let finalEnd = max(endTs, existing?.endTs ?? endTs)

        // Use Repository's active-strap-first, clipped counter window so auto-save and workout detail
        // report exactly the same steps, including both partial boundary intervals.
        let rawTicks = await strapStepTicks(from: startTs, to: finalEnd)
        let correction = stepTicksPerStep.isFinite ? min(max(stepTicksPerStep, 0.5), 30.0) : 1.0
        let counterSteps = rawTicks.map { max(0, Int((Double($0) / correction).rounded())) }
        let cadenceSteps = medianCadenceHz.flatMap { cadence -> Int? in
            guard cadence.isFinite,
                  (MotionCadenceBoutDetector.minimumCadenceHz...MotionCadenceBoutDetector.maximumCadenceHz)
                    .contains(cadence) else { return nil }
            return max(0, Int((Double(finalEnd - startTs) * cadence).rounded()))
        }
        let existingCadenceEstimate = existing?.notes?.contains("Estimated cadence steps") == true
        let resolvedSteps = counterSteps
            ?? (existingCadenceEstimate ? cadenceSteps ?? existing?.steps : existing?.steps ?? cadenceSteps)
        let stepsAreEstimated = counterSteps == nil
            && (existingCadenceEstimate || (existing?.steps == nil && cadenceSteps != nil))

        // GPS is the only measured distance. Otherwise use counter/cadence steps multiplied by the
        // wearer's height-derived stride, progressively calibrated from GPS runs/walks.
        let existingHasGPS = existing?.notes?.contains("GPS distance") == true
        let gpsDistance = distanceM ?? (existingHasGPS ? existing?.distanceM : nil)
        let stride = strideLengthM.flatMap { $0.isFinite && $0 > 0 ? $0 : nil }
        let estimatedDistance = gpsDistance == nil
            ? resolvedSteps.flatMap { steps in stride.map { Double(steps) * $0 } }
            : nil
        let resolvedDistance = gpsDistance ?? estimatedDistance

        // Use the stored HR trace when it covers the workout, not the smoothed dashboard BPM.
        // The motion-minute BPM is retained only as a fallback when raw coverage is insufficient.
        let hrSamples = (try? await store.hrSamples(deviceId: deviceId, from: startTs,
                                                     to: finalEnd, limit: 10_000)) ?? []
        let restingHR = today?.restingHr.map(Double.init)
        let analyticsProfile = ProfileStore.persistedAnalyticsProfile
        let hrMax = strainProfile?.hrMax ?? analyticsProfile.maxHR
        let hasHRCoverage = WorkoutHeartRateFill.hasUsableCoverage(hrSamples, start: startTs, end: finalEnd)
        let hrSummary = hasHRCoverage
            ? WorkoutHeartRateFill.resolve(band: hrSamples, watchMinutes: [], start: startTs, end: finalEnd,
                                           maxHR: hrMax, restingHR: restingHR)
            : nil
        let resolvedAverageHR = hrSummary?.averageHR ?? averageBpm ?? existing?.avgHr
        let resolvedMaxHR = hrSummary?.maxHR ?? existing?.maxHr
        let resolvedStrain = hrSummary?.strain ?? existing?.strain
        // Do not freeze an HR/pace fallback into the row here. The Workouts list and detail
        // resolve this window against the strap's own five-minute energy buckets after the
        // confirmed-workout refresh, then use the same HR/pace estimate only if strap coverage
        // is insufficient. A stored fallback would prevent that higher-quality strap price.
        let noteBase = existing?.notes?.components(separatedBy: " · ").first
            ?? "Automatically detected from WHOOP 5 live motion cadence"
        var noteParts = [noteBase]
        if gpsDistance != nil { noteParts.append("GPS distance") }
        else if estimatedDistance != nil { noteParts.append("Estimated stride distance") }
        if stepsAreEstimated { noteParts.append("Estimated cadence steps") }
        let note = noteParts.joined(separator: " · ")
        let row = WorkoutRow(startTs: startTs, endTs: finalEnd, sport: sport,
                             source: existing?.source ?? WorkoutSource.confirmedSuggestionSource,
                             durationS: Double(finalEnd - startTs),
                             energyKcal: nil,
                             avgHr: resolvedAverageHR, maxHr: resolvedMaxHR, strain: resolvedStrain,
                             distanceM: resolvedDistance, zonesJSON: existing?.zonesJSON,
                             notes: note, steps: resolvedSteps)

        if let existing, existing.endTs == row.endTs, existing.sport == row.sport,
           existing.energyKcal == row.energyKcal, existing.avgHr == row.avgHr,
           existing.maxHr == row.maxHr, existing.strain == row.strain,
           existing.distanceM == row.distanceM, existing.steps == row.steps,
           existing.notes == row.notes {
            return counterSteps
        }

        do { _ = try await store.upsertWorkouts([row], deviceId: deviceId) }
        catch { return counterSteps }
        if let existing, existing.sport != sport {
            _ = try? await store.deleteWorkouts(deviceId: deviceId, sport: existing.sport,
                                                from: existing.startTs, to: existing.startTs)
        }
        scheduleEnergyRefresh(coveringStart: startTs)
        await refresh()
        return counterSteps
    }
    /// Undo: deletes the answer and its workout. Auto-logged spans are tombstoned so reload cannot recreate them.
    func undoActivitySuggestion(_ s: ActivitySuggestions.Suggestion) async {
        guard let store = await storeHandle() else { return }
        let track: ActivitySuggestionAnswer.Track = s.track == .walk ? .walk : .heartRate
        let answers = (try? await store.activitySuggestionAnswers(from: s.start, to: s.end)) ?? []
        let answer = answers.first(where: { $0.track == track && $0.candidateStartTs == s.start })
        if answer?.origin == .automatic {
            let defaults = UserDefaults.standard
            var dismissed = defaults.stringArray(forKey: "workouts.autoDetectDismissed") ?? []
            let token = "\(s.start):\(s.end)"
            if !dismissed.contains(token) { dismissed.append(token) }
            defaults.set(dismissed, forKey: "workouts.autoDetectDismissed")
        }
        if let key = answer?.workout,
           let row = await workoutRows(days: ActivitySuggestions.listDays + 2).first(where: {
               $0.startTs == key.startTs && $0.sport == key.sport
                   && WorkoutSource.classify($0.source) == .confirmed
           }) {
            await deleteWorkout(row)
        }
        _ = try? await store.deleteActivitySuggestionAnswer(track: track, candidateStartTs: s.start)
        await refresh()
    }
}
