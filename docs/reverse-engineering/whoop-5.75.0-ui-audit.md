# WHOOP 5.75.0 UI parity audit

**Reference:** WHOOP iOS 5.75.0, build 738478, bundle `com.whoop.iphone`  
**Source IPA:** `https://github.com/ribhupanwar/dsta/releases/download/whoop-5.75.0/pulseforge.ipa`  
**Extraction run:** [DSTA workflow run 41341431589](https://github.com/ribhupanwar/dsta/actions/runs/41341431589)  
**Artifact:** `whoop-5.75.0-ipa-ui-reference`, SHA-256 `696e1b2896fa4c1fe2dee38c21c74c5df0fa8a250fdbf630500275308f140937`  
**Analysis migration required:** no (audit/documentation only).

## Verified extraction inventory

The successful static extraction contains 4,509 indexed app-bundle entries, including:

- 180 NIB resources
- 70 storyboard-compiled NIB entries
- 3,977 localized string resources
- 38 asset-catalog `Assets.car` resources
- UI-related executable symbols / class names and resource paths
- NIB class and outlet/action wiring reports where decoding was possible

The IPA identifies `Payload/Whoop.app`, bundle ID `com.whoop.iphone`, version `5.75.0`, build `738478`.

**Important limitation:** this is a compiled application. The extraction does not recover original SwiftUI source, all runtime constraints, complete screen state, animation timing, or authoritative screenshots. The inventory is evidence for component discovery and terminology, not proof of pixel geometry. Exact pixel parity requires screen captures from the running reference app and the candidate build at matching device size, content state, and appearance.

## Additional screen-structure evidence from the decoded reference

These are verified strings and NIB wiring, not inferred pixel measurements:

- The localized `MainTab` resource names the primary destinations **Home, Health, Coaching, Community, More**, with **Plan, Profile, Shop** also present in the tab vocabulary. The home onboarding copy says daily metrics, activities and weekly trends live on Home, and that Sleep, Recovery and Strain pillars are accessed by swiping. It also describes a central action button for starting an activity, opening the journal and other common actions.
- `ActivityStrainView.nib` decodes to 313 objects / 21 classes and includes `LiveHeartRateZonesView`, `WHPCircularProgressView`, a strain-target annotation and a circular-slider target view. The paired localized strings explicitly distinguish Activity Strain, Heart Rate, Live, Calibrating, Disconnected and Enable Bluetooth states.
- `StrainCoachViewNew.nib` decodes to 723 objects / 33 classes. Its wiring includes large and small circular strain progress views, a circular target slider, a recovery/strain graph, estimated-day-strain labels, a locked state, a switch and controls for reset/resize/help. This supports a layered target-coaching surface rather than a single score card.
- The English Strain Coach strings distinguish Activity Strain, Current Day Strain and Estimated Day Strain; they name optimal/restorative/overreaching states and describe a recovery-vs-day-strain graph. The app's proprietary coaching copy/model must not be copied; Woop should use its own transparent local explanation.
- The extracted Sleep Coach bundle contains dedicated onboarding, alarm status, alarm mode, sleep-goal selection, sleep-need receipt/graphs and wake-time editing resources. This is evidence of distinct sleep-coach subflows, not evidence that all of those cloud/product flows should be reproduced.
- `Home.storyboardc/HOME_ID.nib` identifies a `HomeViewController` scene. The home screen also has separate localized resources for its action button, onboarding and loading/error states.
- The English live-HR strings distinguish BPM, calibrating, disconnected, firmware-updating and off-body states, plus Zones 0–5. These state distinctions should remain explicit in the local UI when the strap provides enough evidence.

No WHOOP font, image, logo, binary, or proprietary implementation is to be copied into Woop. These findings are used only to establish screen hierarchy, state vocabulary and component roles.

## Woop codebase map (main at audit time)

- iOS shell/navigation: `StrandiOS/App/RootTabView.swift`
- Home dashboard: `Strand/Screens/TodayView.swift`
- Existing alternate overview: `Strand/Screens/OverviewDashboardView.swift`
- Existing trend dashboard: `Strand/Screens/TrendsDashboardView.swift`
- Sleep and sleep history: `Strand/Screens/SleepView.swift`
- Health/vitals and live HR: `Strand/Screens/HealthView.swift`
- Training load / strain context: `Strand/Screens/TrainingLoadView.swift`
- Manual HRV capture: `Strand/Screens/HRVSnapshotView.swift`
- Typography (must remain unchanged): `Packages/StrandDesign/Sources/StrandDesign/Typography.swift`

Woop already has functional domain screens and a reusable design system. The parity task should primarily reshape presentation and navigation while retaining existing models, stores, data provenance, and BLE ownership. The current Today implementation is a dense dashboard with recovery/insight hero, a metric grid, recent workouts and source footer; Sleep already has a hypnogram/stage breakdown, sleep-need/debt metrics and trends; Health isolates its live-HR leaf from static vitals to avoid a full-screen refresh on every BLE tick. Do not replace these existing data paths merely to imitate a screenshot.

## Screen/component parity worklist

| WHOOP area evidenced by extraction | Existing Woop implementation | Work required |
|---|---|---|
| Home / daily overview and action button | RootTabView, Today, Overview, Trends dashboards | Capture reference and Woop screenshots; select one canonical home composition; tune header, score hero, card ordering, density, action affordance and bottom navigation against reference |
| Recovery / strain / sleep pillars | Today and Overview score components; SleepView; TrainingLoadView | Match hierarchy, ring/gauge geometry, score labels, comparison copy and drill-down transitions using existing local calculations |
| Strain target / coach graph | TrainingLoadView and existing strain coaching surfaces | Reconcile local lane/adaptation evidence with the reference's target slider, recovery-vs-strain graph, estimated-day-strain and locked/available states; do not copy WHOOP's proprietary recommendations or text |
| Sleep detail and sleep coach surfaces | SleepView and sleep presentation store | Match stage timeline/hypnogram, sleep need, performance/efficiency/consistency, debt and detail navigation where locally supported; alarm/coach settings only where a local equivalent exists |
| Health / live HR / vitals | HealthView | Match live-HR hero, zones and explicit connection states, plus RHR, HRV, respiratory rate, SpO2 and skin-temperature card hierarchy; do not display unsupported or unvalidated values as measured facts |
| Activities / workout history | Existing workout screens and Today tiles | Match activity list, activity detail, strain presentation, workout start/stop and history navigation |
| Journal | Existing journal-related screens (confirm exact route in app shell) | Match behavior-selection and daily journal presentation only where the local feature exists |
| Strap/device settings | Existing device manager and connection status surfaces | Match device status, battery and connection settings while preserving existing BLE manager and safe command allowlist |
| Community / account/cloud features | Not part of local-first Woop scope | Do not recreate server-backed social graph, chat, leaderboard, account or cloud-only functionality |

## Non-negotiable implementation constraints

1. **Preserve source language by module.** Existing Swift stays Swift; existing Kotlin stays Kotlin. Do not mechanically convert the whole repository to Swift.
2. **Preserve Woop typography.** Do not replace font files, font registrations, `StrandFont`, or typography tokens. WHOOP's bundled DINPro/other font files are not to be copied.
3. **Clean-room implementation only.** Do not copy WHOOP executable code, proprietary assets, logos, or decompiled implementation. Use the extraction for factual UI inventory and terminology, then build original equivalents with Woop components.
4. **Protect the data path.** UI work must not replace BLE, packet decoding, storage, analytics, or provenance. Keep screens bound to current local repository/store APIs.
5. **No false data parity.** A visual slot may show a local metric only when its source and confidence are known. Missing strap-derived data must remain an honest empty/unavailable state, not fabricated.
6. **Keep offline-first scope.** No WHOOP account/session, cloud sync, telemetry, or community backend should be introduced as part of visual parity.
7. **No analysis recipe bump for presentation-only changes.** Record `Analysis migration required: no` for UI-only commits.

## Completion gate for “indistinguishable” UI

A visual-parity claim is not accepted until all of the following are checked on the same iPhone model / logical resolution and same app appearance:

- Primary navigation and tab-bar layout
- Home dashboard above-the-fold and full-scroll screenshots
- Recovery, Strain, Sleep, Health/Vitals, Activity list and Activity detail
- Sleep stages/debt/need drill-down
- Device settings and disconnected/connected states
- Loading, empty, error and populated states
- Tap targets, sheets, push transitions, back behavior and scroll restoration
- Dynamic Type / safe-area behavior where relevant
- No regressions to BLE connection, live HR/RR, sync, storage or existing metric calculations

For each screen, keep paired reference/candidate screenshots and a short discrepancy list. Tune geometry and behavior from those captures; do not infer pixel values from compiled NIB names alone.

## Current status

- [x] Exact WHOOP 5.75.0 IPA downloaded and SHA-256 verified by the DSTA workflow.
- [x] Static UI resource inventory and available NIB/storyboard/string/symbol extraction completed.
- [x] Home, strain-coach, live-HR and sleep-coach structural strings/NIB evidence reviewed.
- [x] Woop source locations and typography constraints identified.
- [x] Clean-room, language-preservation and font-preservation rules recorded.
- [ ] Runtime reference screenshots collected for each primary screen.
- [ ] Screen-by-screen visual diff performed.
- [ ] UI changes implemented and tested in Woop.
- [ ] iOS build and installable IPA verified.

This document records a verified static audit, not a claim that the UI has already been ported. The remaining visual implementation cannot be honestly certified from static IPA metadata alone.


## Cross-repository comparison: DSTA experiments vs Woop (2026-11-02)

### What exists in DSTA

The DSTA repository contains several earlier clean-room SwiftUI experiments on separate branches:

- `feature/woop-reference-ui-port`: `PulseForge/WoopReferenceHomeScreen.swift`, `WoopReferenceRecoveryScreen.swift`, and `WoopReferenceSleepScreen.swift`.
- `feature/whoop-style-home-dashboard`: `PulseForge/WhoopStyleTodayDashboard.swift`.
- `ui/whoop-native-shell-v1`: the reference screens plus additional history/recovery experiments.
- DSTA main includes a separate PulseForge BLE/metrics app and the WHOOP archive inspection workflow.

These files are DSTA-authored reference implementations, not recovered WHOOP source. They are useful as prior UI experiments and as a record of which visual ideas were tried. Their standalone data bindings and design tokens are not drop-in Woop components.

### Archive identity and access finding

DSTA `Whoop.zip` is stored through Git LFS. The GitHub contents endpoint returns only its LFS pointer (OID `80a3ac0667195b2203da79c4d859d0280f0e49fc8b320bbe26e5e0e058bbe9fd`, declared size 306,384,126 bytes), not the archive bytes. The separately verified 5.75.0 IPA extraction artifact described above is the available static UI evidence for this comparison. Do not treat the LFS pointer as a source-code archive or claim that the original WHOOP source is available.

### Reuse vs rebuild map

| Area | DSTA experiment | Woop current source | Decision |
|---|---|---|---|
| Home dashboard | `WoopReferenceHomeScreen`, `WhoopStyleTodayDashboard` | `Strand/Screens/TodayView.swift` (large, mature dashboard) | Rebuild presentation in the existing Woop screen; reuse only composition ideas such as a compact metric strip, score hero and drill-down affordances. Do not transplant DSTA model/environment objects. |
| Recovery | `WoopReferenceRecoveryScreen` | Today recovery hero plus recovery detail/contributor surfaces in `HealthView.swift` | Recompose existing Woop recovery readouts into a dedicated WHOOP-like detail hierarchy; preserve Woop score calculation, calibration and provenance. |
| Sleep | `WoopReferenceSleepScreen` | `Strand/Screens/SleepView.swift` | Woop already has substantially richer sleep history, hypnogram, need/debt ledger and trends. Rework hierarchy/navigation only; do not replace it with the smaller DSTA screen. |
| Health / live HR | DSTA PulseForge has its own BLE manager and live-HR components | `Strand/Screens/HealthView.swift` | Keep Woop's live-HR chart and state handling; reorganize into WHOOP-like Health surface and metric detail routes. Never connect DSTA's Bluetooth manager to Woop. |
| Strain / coaching | DSTA dashboard displays a provisional cardio-load value and leaves unsupported strain blank | `Strand/Screens/TrainingLoadView.swift`, Today strain surfaces, Coach UI | Build a local strain/coach presentation around Woop's existing transparent load lanes. Do not present DSTA cardio-load points as WHOOP strain or copy proprietary coaching logic. |
| Navigation | DSTA screens are sheet-driven from a single Home prototype | `StrandiOS/App/RootTabView.swift` owns five independent NavigationStacks and routes | Navigation needs deliberate Woop-native restructuring, not a wholesale shell replacement. WHOOP's extracted tab vocabulary is Home / Health / Coaching / Community / More; Community/cloud features remain out of Woop's offline-first scope. |
| Typography | DSTA reference screens use many direct `.system(size:)` declarations and a separate replica palette | `Packages/StrandDesign/Sources/StrandDesign/Typography.swift` | Do not port DSTA font declarations or WHOOP font assets. Keep Woop's existing `StrandFont` and tokens unchanged. |
| Data source | DSTA prototype reads its own `HealthKit` and PulseForge insight objects | Woop uses its own Repository, stores, local strap data and provenance | Bind all redesigned views to Woop's existing data owners. No Apple Health substitution for strap-derived metrics and no duplicate parallel model. |

### Confirmed implementation order

1. **Navigation map first:** map WHOOP Home/Health/Coaching/More destinations to existing Woop routes. Keep Community explicitly out of scope unless a local, non-social equivalent is justified. Preserve the current independent navigation paths, quick-action sheet and device routing.
2. **Home composition second:** use TodayView as the data-owning screen; consolidate its existing hero/metrics/activity surfaces into one canonical home layout. Avoid maintaining Today and Overview as competing home implementations.
3. **Health third:** promote the existing HealthView/live-HR/vitals content into the primary Health destination, keeping high-frequency live-HR observation isolated from static cards.
4. **Recovery and Strain drill-down fourth:** reuse current score and load models; add visual hierarchy and navigation, not new scoring formulas.
5. **Sleep fifth:** preserve SleepView's existing analytical depth and tune its hero, stages, need/debt and history navigation to the reference.
6. **Activities and device settings sixth:** map existing workout/activity and device-manager screens to the corresponding WHOOP feature roles without touching BLE command behavior.
7. **Validation last:** paired screenshots on the same device/appearance, tap-flow checks, then local tests and an iOS build/IPA check.

### Specific code boundaries

- Woop iOS UI: SwiftUI in `StrandiOS/` and `Strand/Screens/`; preserve each module's existing language and ownership.
- Woop shared logic: retain the current `Strand` / package APIs; no new scoring math is implied by this visual comparison.
- Woop typography: protected file `Packages/StrandDesign/Sources/StrandDesign/Typography.swift`; no edits.
- DSTA PulseForge BLE/protocol files (including `WhoopBluetoothManager.swift`) are not UI dependencies for Woop.
- Do not copy WHOOP binaries, decompiled implementation, fonts, images, logos, or proprietary coaching text. Use the reference only for screen roles, state vocabulary and interaction inventory.
- Presentation-only implementation records `Analysis migration required: no`; changes to metric meaning, source precedence or stored derivations must be separately reviewed for migration impact.

### Comparison conclusion

DSTA's reference UI branches are useful prototypes, but the production Woop codebase already has deeper screen functionality and a more mature shared design/data architecture. The correct path is **selective visual learning, then native Woop refactoring**—not replacing Woop screens with DSTA prototypes and not merging DSTA's standalone app. Runtime WHOOP screenshots are still required before claiming pixel-level parity.


## Binary-level reverse-engineering pass (2026-11-02)

### What the original executable actually exposes

A second pass inspected the extracted executable-symbols.txt, objc-metadata.txt, executable-strings.txt and localized strings from the exact 5.75.0 build. The Mach-O is not a source archive: most useful Swift implementation bodies are not recoverable from these reports. However, Objective-C runtime metadata and retained Swift type names expose a meaningful internal type map.

Verified original-app types / fields include:

- Cycle/domain layer: Cycle, CycleRecovery, CycleSleep, CycleStrain, CyclesManager, CycleConverter, NewCyclesService, and CycleProgressViewModel.
- Strain processing: StrainAccumulator, BackfillingStrainAccumulator, HeartRateBucket, rawStrainScore, scaledStrainScore, and calibration-packet counters.
- Recovery: currentRecovery, recoveryScore, greenRecoveryScore, yellowRecoveryScore, redRecoveryScore, recoveryCalibrating, and a dedicated CycleRecovery model.
- Sleep: WhoopSleepCoach types including SleepCoachManager, SleepCoachService, SleepCoachViewModel, SleepNeedBreakdown, SleepNeedReceiptViewModel, SleepNeedGraphsViewModel, OptimalSleepEndpoints, RecommendedTimeInBed, and smart-alarm services.
- Live HR: a separate WhoopLiveHeartRate module with LiveHRStrapInteractor, LiveHRCombineInteractor, LiveHRViewModel, StreamProcessingState, AccumulatedStateStore, ConnectionSnapshot, and WhoopLiveHeartRateAccumulator.
- HR settings/validation: HeartRateValidator, plus original model fields for hrv, leaderboardHRV, leaderboardRHR, and currentHRValues.
- Original executable retains step-related names including HealthKitStepCountRequest, HealthKitStepCountSubmissionDTO, delayedStepCountProcessingWorkItem, lastStepCount, currentStep, and stepValues.

These are architecture/type/field observations, not reconstructed algorithms. Runtime metadata method IMP offsets and stripped Swift symbols are not enough to safely recreate proprietary method bodies.

### Critical step-counter finding

The exact 5.75.0 executable's retained string table does not expose the literal keys step_motion_counter or activity_class. It does expose the HealthKit step request/submission types and step-processing fields above. Therefore the IPA metadata alone does not prove that WHOOP's displayed daily step total is computed from the strap's step_motion_counter@57, nor does it reveal the counter-to-steps coefficient.

Woop currently has two distinct step paths:

1. WHOOP 5/MG classed historical counter path: HistoricalStreams.swift extracts step_motion_counter and activity_class; StepsCounter.swift treats the counter as a cumulative wrap-aware u16, filters class 1/2 when classes exist, rejects implausible deltas and applies per-user tick calibration. Its own comments explicitly call the result an estimate and note that the field's semantics were previously unverified against the app.
2. WHOOP 4.0 sparse-motion path: StepsEstimateEngine.swift estimates daily steps from motion volume, calibrated against phone step history. This is explicitly not a true pedometer because 4.0's sparse motion records do not expose individual footfalls.

For WHOOP 5/MG, Whoop5RawImu.swift separately decodes a 1244-byte raw 6-axis frame into 100 accelerometer + 100 gyroscope samples per second. This is a high-rate signal suitable for independent gait research, but it is not proof that the original app uses this exact frame for its displayed step total.

What remains to crack: determine, with paired real-device captures and app-visible step totals, whether 5/MG daily steps come from the classed cumulative counter, raw IMU processing, HealthKit, or a fused/server-supplied value; identify reset/wrap semantics, calibration, and day-boundary attribution. Keep competing hypotheses separate until data discriminates them. Do not change production step scoring based only on metadata names.

### DSTA vs Woop implementation comparison

- DSTA main has Gen5R21IMUDecoder.swift for 1244-byte 5/MG raw IMU frames, and a large WhoopBluetoothManager.swift that owns its separate PulseForge BLE path. Woop's Whoop5RawImu.swift already implements the same 1244-byte / 100+100 sample structure with a more explicit frame-layout and scale contract. Do not port DSTA's BLE manager into Woop.
- DSTA RecoveryScoreCalculator.swift is a small 3-day median-baseline heuristic (60/40 HRV/RHR blend). Woop RecoveryScorer.swift is a broader baseline-normalized transparent model with additional inputs and extensive regression coverage. Do not replace Woop's recovery engine with DSTA's smaller prototype.
- DSTA SleepNeedCalculator.swift is an explicit baseline/debt/nap/strain heuristic. Woop's SleepStager, sleep need/debt and analysis pipeline are substantially broader. Do not replace them with DSTA calculator code.
- DSTA's reference screens are separate UI prototypes; they are not the source of Woop's shared analytics or protocol packages.
- Woop already has dedicated StepsCounter, StepsEstimateEngine, SleepAwareStepCounter, StepsMotionCache, Whoop5RawImu, and historical-stream extraction. This is the better engineering home for continued step investigation; DSTA remains useful for independent capture/decoder experiments.

### Next reverse-engineering sequence

1. Preserve the original IPA and extraction hashes as immutable evidence.
2. Extract and inspect original app's step-related localized strings and all references to HealthKit step request/submission, step fields and any available DTO schemas. Treat server/HealthKit references as a separate possible source.
3. On an owned 5/MG strap, collect synchronized raw offload frames, live raw IMU frames, counter/class samples, and the official app's displayed step total over controlled walk / run / wrist-motion / rest intervals.
4. Compare counter deltas, IMU gait events, and displayed totals at the same timestamps. Include midnight/day-boundary and reconnect/offload cases.
5. Implement only a discriminated, tested local interpretation in Woop's existing protocol/analytics layers; keep original BLE, storage, scoring and fonts untouched until evidence warrants a change.
6. Run focused protocol/analytics tests and the repository-required Tools/local-tests.sh on the committed tree before pushing any app/package code.

This is a reverse-engineering evidence update only. No app source, BLE behavior, analytics or typography was modified. Analysis migration required: no.


### Additional localized evidence about step provenance

The English 5.75.0 localized resources include HealthKit settings copy explicitly describing Apple Health connection as importing metrics “from Sleep to Steps”, plus `RockyWidget.title` = “Today’s Step Count”. This makes Apple Health ingestion a concrete original-app data-source candidate, alongside the strap/offload and server-derived possibilities. It still does not prove which source supplies the primary in-app daily step total or how duplicates are reconciled. The exact precedence must be established by controlled source toggles and paired observations; never merge HealthKit and strap totals blindly.


## UI conversion execution plan (2026-11-02)

The production Woop screens were re-opened for implementation planning. This section is deliberately a screen-role mapping, not a claim that the UI port is finished.

| WHOOP 5.75.0 surface / role | Existing Woop implementation to adapt | Conversion boundary |
|---|---|---|
| Home / daily overview | `Strand/Screens/TodayView.swift`, `LiquidTodayView.swift`, `OverviewDashboardView.swift` | Match hierarchy, pillar entry points, daily summary and activity entry; retain current day selection, refresh and data states |
| Recovery pillar | Today hero / charge breakdown and `HealthView.swift` | Present recovery score, state, contributors and history using existing `RecoveryScorer` outputs; no new scoring math |
| Sleep pillar | `Strand/Screens/SleepView.swift` and sleep presentation/model components | Rework header, sleep performance, stages, need/debt and trend navigation; retain existing sleep model and provenance |
| Strain pillar | `Strand/Screens/TrainingLoadView.swift`, activity strain components and live workout screens | Rework strain gauge, target and activity details; preserve effort scale and workout session state |
| Health / vitals | `Strand/Screens/HealthView.swift`, `HRVSnapshotView.swift`, `SkinTempCardsView.swift` | Group HR, HRV, RHR, respiratory, SpO2 and temperature with honest empty/calibration states |
| Trends / history | `Strand/Screens/TrendsDashboardView.swift`, `TrendsView.swift` | Align chart hierarchy, date ranges and metric drill-downs; preserve current series and source labels |
| Activity / device / more | Existing workout, device and settings routes under `Strand/Screens/` and `RootTabView.swift` | Match navigation roles and interaction states; no BLE manager or command changes |

### First implementation slice

Start with the Today root and shared visual primitives, then reuse those primitives on Recovery, Sleep, Strain and Health. Keep all metric values bound to existing repository/view-model outputs. Avoid introducing parallel demo values, mock production state, or a second navigation stack. Preserve `StrandDesign/Typography.swift` and existing font tokens.

### Verified starting point and current status

- Production iOS shell already routes five independent tab stacks and supports four Today layouts (Classic, Liquid, Trends, Overview). The selected layout is persisted under `TodayDashboardStyle.storageKey`; do not replace the shell to imitate WHOOP's tab bar.
- `OverviewDashboardView.swift` already describes itself as a reference-matched compact overview and renders Recovery/Strain/Sleep rings, focus cards and health list. It is a useful starting point, not proof of parity with WHOOP 5.75.0.
- `TodayView.swift` contains existing score states, provenance, live-session state, daily steps, HR trace and data-source disclosures. Keep these behaviors when changing presentation.
- No production UI source was changed in this kickoff pass. No screenshot-based visual comparison or iOS build has been performed in this pass.
- Analysis migration required: no (planning/documentation only).


### First production UI change (2026-11-02)

- Updated `StrandiOS/App/RootTabView.swift` so fresh installs default to the existing `OverviewDashboardView` rather than `LiquidTodayView`.
- Existing `@AppStorage` selections remain respected; no forced reset or overwrite of a wearer's saved dashboard preference.
- The Overview screen already binds the existing Recovery/Strain/Sleep values, supports metric drill-downs, and retains the health list/focus cards. This makes the most WHOOP-like existing Home composition the starting default without introducing mock metrics or duplicate stores.
- All five independent tab NavigationStacks, quick actions, deep links, device sheets, and workout presentation remain untouched.
- No typography, BLE, protocol, storage, scoring, or metric provenance code changed.
- Analysis migration required: no (presentation default only).
- Validation status: source edit committed; repository-required `Tools/local-tests.sh`, simulator screenshots, and IPA build have **not** been run in this environment. Do not treat this commit as a verified build or completed UI conversion.
