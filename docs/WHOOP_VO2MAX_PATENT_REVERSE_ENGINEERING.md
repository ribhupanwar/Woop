# WHOOP VO2 Max patent reverse-engineering: findings and implementation map

Audit date: 2026-11-06

## Primary patent
- Publication: US 2026/0263002 A1, Measuring maximal oxygen consumption
- Published: 2026-09-10; assignee: WHOOP, Inc.
- Public text: https://patents.google.com/patent/US20260263002A1/en
- Reporting: https://the5krunner.com/2026/11/03/quick-read-whoop-vo2-max-patent/

This reconstructs the disclosed architecture; it does not claim to reproduce WHOOP's private trained model or weights.

## Disclosed architecture

### Passive baseline
The first model may be a regression model using wearable data such as sleep PPG-derived heart rate, demographic/profile inputs, heart-rate-zone statistics during activity, heart-rate dynamics/recovery, motion/accelerometer/gyroscope features, and potentially PPG waveform morphology. The model can use a historical window and run daily or weekly. Patent language allows models, weights and coefficients to reside on a wearable, phone or server.

### GPS/run-augmented model
When suitable GPS running data exists, a higher-quality model can combine physiology during the run with pace/speed, distance, altitude/elevation, terrain, heart-rate response to workload, normalized pace-to-heart-rate statistics (including percentiles), and context such as altitude, temperature and weather. Regression and other ML approaches are contemplated, but fitted coefficients and a complete training set are not disclosed. GPS evidence can expire after a lookback interval (90 days is an example). A GPS-derived offset may be carried into the passive model after GPS evidence expires, with smoothing or gradual decay.

### Clinical/lab calibration
A dated clinical VO2 measurement can calibrate future outputs. One disclosed approach computes the difference between the clinical value and the baseline estimate around the test date, then applies that correction prospectively. The clinical anchor can persist longer than GPS evidence, subject to removal, replacement or aging rules.

### Model selection and continuity
This is a stateful estimator, not one equation. It selects the best eligible model from currently available data, maintains continuity when a higher-quality source expires, and may combine model outputs. Relevant patent sections: paragraphs [0098], [0102], [0105]-[0119], [0127]-[0131] and claims 1-24.

## WHOOP 5.75.0 binary findings already verified
The pinned IPA audit (build 738478; SHA-256 8a5deedc59567612683feb77dd7348238de89437123946b3344bc6ff1e90af8a) verified data keys vo2max_score, vo2MaxMeasurement, vo2MaxValue, vo2MaxUnit, cardioFitnessLevel and score_timestamp; source labels INTERNAL_ESTIMATE, MANUAL_LAB_TEST, MANUAL_OTHER and MANUAL_WEARABLE; HealthKit identifier HKQuantityTypeIdentifierVO2Max; and trend routes /progression-service/v3/trends/, /manual/readings, /manual/readings/paginated?next_token= and /readings/paginated?next_token=.

No self-contained estimator formula, coefficient set or embedded on-device model was found in that static audit. This is consistent with, but does not prove, server-side inference. Earlier audit: https://github.com/ribhupanwar/dsta/actions/runs/41804651721

## Woop codebase mapping (branch fix/unified-today-auto-gps-sleep)

| File | Current role | Relation to patent |
|---|---|---|
| Packages/StrandAnalytics/Sources/StrandAnalytics/ExerciseVO2max.swift | Experimental active running estimate using ACSM oxygen cost + HR-reserve extrapolation; timestamp-aligned GPS/HR path and strict quality gates | Independent GPS/run evidence, not WHOOP's fitted active model |
| Packages/StrandAnalytics/Sources/StrandAnalytics/CardioFitness.swift | Jurca 2005 non-exercise estimate and resolver for manual, Apple Watch and population fallback | Transparent baseline fallback, not WHOOP's sleep/PPG trained passive model |
| Packages/StrandAnalytics/Sources/StrandAnalytics/HealthspanVO2.swift | Dated manual and Apple Health resolution; long-walk plausibility floor | Provenance handling, not a passive estimator |
| Packages/StrandCore/Sources/StrandCore/TrainingVO2max.swift | Training VO2-related data model | Needs integration review before changes |

The experimental ACSM/HRR field estimate is deliberately not treated as validated performance evidence. Preserve that guard until longitudinal validation passes.

## Safe reconstruction plan
1. Preserve three separately labelled candidate sources: passive wearable estimate, GPS/run estimate, and clinical/HealthKit measurement.
2. Implement the patent's deterministic mode selector and provenance/transition rules independently of estimator coefficients.
3. Reuse the existing GPS/HR pipeline only as an independent field model; do not relabel it WHOOP.
4. Do not fabricate a passive regression from a handful of profile fields. A real passive model requires labelled training data, ideally lab VO2 measurements paired with historical sleep/PPG/activity features, plus out-of-sample validation.
5. Implement GPS-offset carry-forward with explicit expiry/decay and dated lab calibration; preserve raw estimate, correction and displayed estimate separately.
6. Keep Apple Health/manual lab values as external evidence with source, date, units and body-mass context.
7. Validate against repeated lab or Apple Watch readings over time: MAE, bias, calibration drift and direction-of-change agreement. Synthetic tests validate arithmetic, not physiological accuracy.
8. Add confidence and insufficient-data states. Never silently substitute a population estimate for a measured or validated estimate.

## Unknowns
- WHOOP's actual passive/active model coefficients, weights and training population;
- exact feature definitions, normalization, missing-data treatment and quality gates;
- whether production inference runs on WHOOP servers, the phone, or both;
- exact production GPS qualification rules and offset-decay function.

Do not claim an exact WHOOP formula unless new evidence (model asset, runtime request/response, disclosed equation, or reproducible paired measurements) establishes it.