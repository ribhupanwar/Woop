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
