# Woop consolidated release readiness

Analysis migration required: no. This change only filters stored records for presentation and fixes
navigation gesture ownership. No scores, raw samples, source precedence or derived tables change.

## Product acceptance

The owner runs and works out regularly. The release combines a WHOOP-style daily dashboard with
running performance, sleep, long-term health and recovery-informed training decisions, using Woop's
own identity. Required tabs: Home, Today, Activity, Healthspan, More.

Approved screenshots are the visual acceptance baseline. The baseline images and their device,
display scale and appearance must be identified before claiming zero visual deviation. The images
in `docs/assets/screenshots` are repository examples, not evidence of owner approval.

### Existing reference source identified by the owner

The owner identified `ribhupanwar/dsta` as the existing WHOOP reverse-engineering/reference repository.
Consult that work before requesting duplicate reference material:

- [WHOOP 5.75.0 IPA UI analysis branch](https://github.com/ribhupanwar/dsta/tree/analysis/whoop-5-75-0-ipa-ui),
  commit `034ba05ba78eb43319552e624a82abee7d7929ae`.
- [Successful extraction run](https://github.com/ribhupanwar/dsta/actions/runs/41476885119), artifact
  `whoop-5.75.0-ipa-ui-reference` (artifact ID `13158456060`, available at inspection).
- [DSTA reference UI implementation](https://github.com/ribhupanwar/dsta/tree/feature/woop-reference-ui-port),
  commit `8d946e38e4e298d770a53d619093f985ac2738ce`: Home, Recovery and Sleep reference screens.
- [Existing Woop cross-repository audit](https://github.com/ribhupanwar/Woop/blob/audit/whoop-5-75-0-ui-parity/docs/reverse-engineering/whoop-5.75.0-ui-audit.md),
  branch head `e36c514cd81241bbfcab9888b5e591202db46772`.

That audit records the exact app version/build, static NIB/storyboard/resource findings and a reuse
map. It explicitly leaves runtime screenshots and visual comparison unchecked. DSTA's independent
SwiftUI experiments are references to adapt to Woop's existing data layer, not recovered WHOOP source
or a completed pixel-parity certification. Preserve Woop's verified readouts when adapting them.

No unavailable sensor input may become a fabricated number. Measured, imported, manually entered,
estimated and predicted values must be distinguished. A calculated score is not a sensor measurement.

## Source inspection at ea260337

These are code findings, not completed hardware or end-to-end verification.

| Feature | Evidence | Remaining acceptance |
| --- | --- | --- |
| Five primary tabs | `StrandiOS/App/RootTabView.swift` | Screenshot comparison and device navigation test |
| Activities timeline and actions | `Strand/Screens/TodayView.swift` | Verify sleep/workout taps, Add Activity and Start Activity on device |
| Recovery, strain, HR and sleep | Analytics package, repository and Today views | Compare readouts to stored inputs; missing/stale source states |
| Sleep timing consistency | `Packages/StrandAnalytics/Sources/StrandAnalytics/SleepTimingConsistency.swift` | Verify history window and displayed provenance; do not call it an Oura score |
| Training load and Coach context | `Strand/AI/CoachTrainingLoad.swift`, `Strand/Screens/TrainingLoadView.swift` | Recovery-based recommendation and change-of-readiness scenarios |
| Healthspan | `Strand/Data/HealthspanSnapshot.swift`, `Strand/Screens/HealthspanSection.swift` | Minimum history and missing steps/profile/VO2 inputs; provisional labeling |
| Cardiovascular fitness | `Packages/StrandAnalytics/Sources/StrandAnalytics/CardioFitness.swift` | Distinguish manual/lab, Apple Watch and formula estimates |
| Oura BLE activity/MET support | `Packages/OuraProtocol`, `Strand/BLE/OuraActivityDump.swift` | Hardware validation; protocol support alone is not full integration |
| Oura cloud import | `Strand/Oura/OuraAPIClient.swift`, `OuraConfig.xcconfig` | Compile-time optional; absent without `OURA_CLOUD_IMPORT`; verify credentials, import coverage and source handling before any support claim |
| GPS map, average pace, HR trace | `Strand/Screens/WorkoutDetailView.swift` | Permission denied, no route, short route, gaps and imported workouts |
| Running pace chart, HR drift, cadence, efficiency, race predictions | Full runner experience not verified by this inspection | Audit each input series and implement/test missing paths; never infer working support from a GPS map |
| 1:45 half-marathon progress | General race/goal infrastructure exists | Explicit goal setup, verified performance inputs and labeled prediction uncertainty; no invented current fitness |

## Corrections in this change

- The selected day's activity timeline uses local calendar boundaries instead of a rolling 14-day
  feed. Sleep is assigned by wake time and workouts by start time. All matching records remain
  visible in ascending start-time order; ties use a stable identifier. The historical heading says
  Activities. Existing recent-workout helper behavior is retained for other callers.
- Home and Today own their day-swipe gestures. The ancestor tab-switch gesture is disabled on both.
- The unsigned IPA workflow observes this isolated release branch so macOS/iOS validation can run.

## DSTA reference adaptation

The next UI pass adapts the independent reference screens at DSTA commit `8d946e38`:

- Home uses Woop branding, a full selected-day date, the Recovery/Sleep/Strain metric strip and the
  reference's 17pt section spacing. Existing contributor, health, goal, workout and customization
  surfaces remain available. The strip reads the same resolved values and scale as the hero rings;
  carried Recovery keeps its caption.
- Recovery uses the reference's 214pt hero and a scored-night date. The Week/Month selector is
  functional over seven/thirty civil days, with missing days left blank instead of substituted with
  zero or visually joined to another night. Invalid/non-finite history values are not charted.
- Non-Liquid Sleep leads with the prepared night's recorded time asleep and a 92pt performance ring.
  The original performance resolver, source badge, sleep need/debt, stages, history and optional Liquid
  presentation remain in use. Missing sleep performance draws an empty track without a numeric score.
- Home and Today Start Activity now open the shared workout picker used by Live/Training, including
  route and strength options. An existing session is re-presented. They no longer open the separate
  Silent Guardian coaching session. Add Activity opens manual entry; Today sleep rows open Sleep.
- Home's selected-day feed no longer silently truncates workouts to eight or combined records to twelve.

These are source changes awaiting macOS/iOS compilation and device screenshots, not completed visual
certification. Regression tests cover week/month civil-day boundaries, leap days and malformed keys.

## Release gates still open

1. Identify approved screenshots and capture all five tabs on the same device/appearance. Compare
   images and review navigation, sheets, chart gestures, empty states and accessibility.
2. Run `Tools/local-tests.sh` on the committed tree, then complete the unsigned device archive.
   This Linux editing environment has no Xcode or Swift toolchain; source inspection cannot replace
   either gate. The branch workflow runs validation on macOS.
3. Validate WHOOP/device data and the selected Oura integration path with real recordings. Verify
   the input source and missing/stale behavior of every requested dashboard metric.
4. Complete runner metrics and half-marathon goal acceptance above. Retain clear unavailable states
   wherever the input cannot support a calculation.
5. Measure extracted IPA/app size, launch time, memory, scrolling and battery on a physical iPhone.
   Artifact ZIP size is not extracted IPA size or installed footprint. Preserve on-device Coach and
   other existing features while profiling; no size optimization is claimed by this change.

Build 256 succeeded and published an unsigned IPA artifact. This is build evidence only, not evidence
that all the product, hardware, performance or screenshot gates above passed.
