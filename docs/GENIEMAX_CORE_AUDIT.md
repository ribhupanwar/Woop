# GenieMax Core audit for Woop

Audited on 2026-11-06 against `satayutata/geniemax-core` main and Woop branch `fix/unified-today-auto-gps-sleep`.

## Decision

Do not add GenieMax as a binary/package dependency. Its package pulls `swift-sodium` for the encrypted vault, while Woop already has its own BLE protocol, persistence and analytics packages. The useful material is the documented analytics approach, not a wholesale merge.

## Findings worth retaining

- **Recovery:** GenieMax uses personal rolling baselines and computes each night's z-scores against the baseline *before* folding that night in. It requires both HRV and RHR to score; respiration and sleep are optional neutral terms. This is a good guard against manufacturing a score when the dominant signals are missing.
- **Sleep data quality:** GenieMax separates the sleep window from stage allocation, checks for sparse nights, and flags gap-truncated nights as partial. It explicitly allows sleep stages to exist without HRV while refusing to fabricate a Recovery score. This separation is worth preserving.
- **Sleep window:** It handles fragmented/biphasic nights with asymmetric merge rules and rejects implausibly long merged windows. The thresholds are heuristics, not validated WHOOP/PSG equivalence.
- **Training load:** GenieMax keeps cardiovascular load, strength load and session-RPE load separate rather than pretending they are interchangeable. Woop should preserve that separation.
- **Fitness age:** It exposes a breakdown of VO2-driven age and secondary modifiers. The modifier coefficients are project choices, not a universally accepted clinical standard; only measured body-composition inputs should influence those terms.
- **VO2max:** Its disclosed Uth estimate (15.3 × HRmax / resting HR) is a population-level shortcut and is not the WHOOP passive model. Do not replace Woop's running/GPS estimator or patent-inspired model selector with it.
- **Steps:** Its StepCounter counts upward crossings of a single scalar acceleration-magnitude threshold with a two-sample refractory period. The repository itself calls this crude and says it needs tuning on real walking data. Do not replace Woop's WHOOP IMU decoder/step pipeline with this simple detector; it is a baseline test idea only.

## Woop-specific integration guidance

1. Keep the WHOOP BLE protocol decoder and raw RR/IMU data path in Woop. GenieMax explicitly contains no BLE or device protocol.
2. Keep live workout RR/HR samples separate from overnight sleep HRV. Only a sufficiently complete overnight window should feed Recovery.
3. Preserve provenance and quality for HR, RR/HRV, respiration, temperature and motion. Missing or sparse signals must stay missing; no neutral-looking synthetic measurement.
4. Keep sleep staging available when HRV is absent, but keep Recovery unavailable until its required overnight HRV and RHR evidence is present.
5. For VO2max, keep the independently measured GPS/HR running estimate, clinical lab anchor and patent-inspired source selector distinct. Never label Uth/Jurca population estimates as WHOOP-equivalent.
6. For training load, keep cardio and strength load separate and expose the source/maturity of each estimate.

## Files reviewed

GenieMax:
- `Sources/GenieMax/Physiology.swift`
- `Sources/GenieMax/RecoveryEngine.swift`
- `Sources/GenieMax/Scores.swift`
- `Sources/GenieMax/SleepStaging.swift`
- `Sources/GenieMax/SleepWindow.swift`
- `Sources/GenieMax/StepCounter.swift`
- `Tests/GenieMaxTests/RecoveryEngineTests.swift`
- `Tests/GenieMaxTests/SleepStagingTests.swift`
- `Tests/GenieMaxTests/StepCalorieTests.swift`
- `docs/HOW-IT-WORKS.md`

Woop:
- `Packages/StrandAnalytics/Package.swift`
- `Packages/StrandAnalytics/Sources/StrandAnalytics/CardioFitness.swift`
- `Packages/StrandAnalytics/Sources/StrandAnalytics/ExerciseVO2max.swift`
- `Packages/StrandAnalytics/Sources/StrandAnalytics/TrainingLoad.swift`
- `Packages/StrandAnalytics/Sources/StrandAnalytics/VO2MaxModelSelector.swift`

## Validation status

This is a source-level comparative audit. No GenieMax source has been copied into Woop, no package dependency has been added, and no new runtime behaviour is claimed. Any algorithm port must be adapted to Woop's existing types and proven with Woop's fixtures/tests and real WHOOP samples before it is enabled.
