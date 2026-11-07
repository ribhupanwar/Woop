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

- Home follows the owner-supplied screenshot: avatar/date/battery row, centered Woop wordmark,
  Sleep/Recovery/Strain rings, My Day and a prominent Activities card with colored metric tiles and
  stacked start/end times. Dedicated dark surfaces and sleep/strain accents live in StrandDesign.
  The screenshot supersedes the earlier metric-strip experiment. Existing contributor, health,
  goal, workout and customization surfaces remain below the pinned rings and daily activity feed.
  Ring values use the existing score resolvers and effort scale; carried Recovery keeps its caption.
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

## Activity correction and automatic-detection evidence

The owner requires same-day activity records and manual correction of a mistaken sport name.
Home's row menu and the activity-detail pencil now open the existing manual editor for local,
legacy-detected and confirmed-detection records. Today also exposes correction through the row's
context menu. Save goes through `Repository.saveManualWorkout`, which already retires the old natural
key, suppresses a corrected legacy detection and carries recorded measurements for editable local
sessions. Imports retain their original provenance and the existing manual-copy flow.

The current `ActivityDetectionScore.Kind` roster is walk/run/cycle/strength/other. `Dancing` exists in
the manual workout catalogue, but a dedicated automatic dance classifier is NOT implemented or verified.
The current confirmation-based detection engine is not equivalent to WHOOP's fully automatic logging.
Home now surfaces its existing suggestions, scoped to the selected current day. Detection settings and
permission choices remain in force. Do not claim all-sport or dance auto-detection from this UI change.

Primary-source research reviewed on 7 November 2026:

- [WHOOP activity detection and correction](https://www.whoop.com/us/en/thelocker/how-whoop-detects-and-labels-your-workouts-activities/):
  separate detection from classification, use HR plus movement, and allow type/time correction while
  retaining cardiovascular observations. A low-confidence bout may remain a generic activity.
- [Oura activity editing](https://support.ouraring.com/hc/en-us/articles/360025577813-Edit-or-Manually-Add-an-Activity):
  edit type/time/duration from the timeline; manually add missed sessions, including historical days.
- [Strava sport correction](https://support.strava.com/en-us/articles/15401975-how-do-i-change-my-activity-type):
  saved activities offer sport changes through Edit; derived analysis can change with sport type.

Remaining detection acceptance: distinguish genuine exercise from stress/heat, test gaps/off-body
signals and overlapping manual/imported workouts, validate run/walk/cycle boundaries, and collect
labeled dance/strength recordings before extending classification. Preserve corrections across a
reanalysis and sync. Auto GPS routes cannot be claimed for time periods without recorded locations.

## Running readout discrepancy investigation

A native session's stored mean can come from sparse live samples while a later sync supplies a denser
historical stream. The full workout list already reconciles native Avg/Max HR against that trace, but
Home deliberately reads with `reconcileHrCap: 0` and previously passed the stored row into detail without
an on-open reconcile. The detail now resolves the single session through the same repository resolver
and refreshes when repository data changes. It retains the existing source and minimum-sample rules,
preserves imported values, and does not rewrite stored samples or energy. Regression cases cover a
stale native average, insufficient historical samples and preservation of imported measurements.

This corrects a reproducible code-path inconsistency; it does not establish the cause of any particular
WHOOP/Woop comparison without matching timestamps and recorded inputs. Separate investigation remains:

- Stored manual-workout rescoring is gated by negligible energy or missing strain; a plausible but
  incomplete saved calorie figure can remain outside that repair path. Read-time HR reconciliation is
  separate, so this gate alone does not prove that the displayed average is stale.
- Live means average captured samples, while a peak can retain a higher within-second reading that
  was deduplicated out of the mean. Inspect sample coverage, recording window and filtering before
  attributing a peak/mean difference to a bug.
- Workout steps prefer a calibrated strap counter, then eligible Health workout steps, then phone
  pedometer. Record the chosen source and coverage before comparing totals or changing calibration.
- Estimated session calories are gross in the local model, while imported Apple active energy is
  retained as supplied. A stored figure currently takes precedence. Compare provenance, active/total
  definition, body inputs and HR coverage rather than adjusting figures to imitate another app.
- The Lite IPA removes the Watch app and PlugIns. Apple Health import and a live Watch companion are
  different capabilities; the former still requires signed-app permissions, and the latter is absent
  from this IPA variant.

CI now observes all package changes and isolates concurrency by branch, so an older branch archive
does not block validation of the current release candidate. iPhone/strap hardware validation remains
required before claiming subscription-independent daily reliability.

## HealthKit on free sideloads

Apple's current [iOS capability table](https://developer.apple.com/help/account/reference/supported-capabilities-ios)
lists basic HealthKit for the no-cost Apple Developer account category as well as paid programs.
Free membership alone therefore does not establish that HealthKit is impossible. The final signed
app, App ID capability, provisioning profile, installing tool and Health permissions all matter.

The custom Woop workflow previously zipped an unsigned app without invoking the repository's existing
capability-template preparation. It now runs `Tools/prepare-woop-lite-healthkit.sh` after all Lite
trimming and before ZIP creation. The script embeds and verifies an ad-hoc request for basic HealthKit
and its access array. It requests neither App Groups nor HealthKit background delivery and includes no
Watch app or extension. It cannot grant capabilities; the sideloader replaces this signature and must
provision and preserve HealthKit. Foreground import and background delivery are different capabilities.

[SideSign PR 3](https://github.com/SideStore/SideSign/pull/3) reports a missing HealthKit App-ID feature
mapping that causes SideStore to strip the entitlement, and its author reports a patched free-account
test. The PR was open/unmerged when inspected; this is not proof that the user's released installer
supports it. Installer name/version and the actual signed profile must be checked before claiming a fix.

The reported installer `0.7.0-20261013.1503` matches
[SideStore nightly run 38463957675](https://github.com/SideStore/SideStore/actions/runs/38463957675),
whose artifact is `SideStore-0.7.0-20261013.1503+12ff39c6.ipa`. Its source commit
`12ff39c6b6c0ccd8180f0834a893a4bbaf7bcd31` pins SideSign at
`752d1ef602aa792a432ffa1e71646dc1ecf7363c`. At that exact dependency revision,
[`Feature.swift`](https://github.com/SideStore/SideSign/blob/752d1ef602aa792a432ffa1e71646dc1ecf7363c/Sources/Models/Feature.swift)
has no HealthKit entitlement-to-feature mapping, and
[`Entitlement.swift`](https://github.com/SideStore/SideSign/blob/752d1ef602aa792a432ffa1e71646dc1ecf7363c/Sources/Models/Entitlement.swift)
omits HealthKit from `freeEntitlements`. This is a version-specific source finding, not merely an
inference from an unmerged PR or the account type. Woop's template alone cannot repair that installer.
A trusted installer build containing the capability mapping/allowlist fix, followed by actual profile
and device authorization verification, is necessary for this signing route. No installer has been
replaced on the user's device and no free-account device installation has been verified here.

The isolated [personal SideStore build](https://github.com/ribhupanwar/Woop/actions/runs/42368174925)
has now passed its baseline-failure/patched-success model checks and completed the upstream IPA
archive/packaging commands. The [test artifact](https://github.com/ribhupanwar/Woop/actions/runs/42368174925/artifacts/13573190553)
contains the IPA, checksum, applied diff and source provenance. The downloaded IPA ZIP integrity and
SHA-256 were independently verified: `2a7dd87a1d424b193e82d3e2154cd4d664c32adc6c618815e8143e7c868eddcb`.
Its bundle remains `com.SideStore.SideStore`, version `0.7.0`; it is not an official release. This is
build evidence only: phone installation, sign-in, Apple provisioning and actual Health import remain
untested. The personal build uses official nightly 1503's authentication and pairing code unchanged.

The owner subsequently reported that the patched installer installs, opens and refreshes successfully.
That verifies the reported installer/refresh path, not HealthKit provisioning. To isolate that next
step without waiting for the full app archive, a
[compatibility repack](https://github.com/ribhupanwar/Woop/actions/runs/42369273196) of successful Woop
Build 257 completed checksum, ad-hoc entitlement embedding, signature and package verification.
Its [artifact](https://github.com/ribhupanwar/Woop/actions/runs/42369273196/artifacts/13572619488)
contains `Woop-HealthKit-compatibility-test.ipa` plus provenance and checksums. The downloaded IPA's
verified SHA-256 is `0483d63ec5f79e875c0f1eb382a911655f27814ab955ed6f0f705793ee33849a`.
Bundle `com.noopapp.noopai`, version `13.0.0`, app source `ea260337`. This changes signing metadata only
and does not include later dashboard, activity-editor or HR-detail fixes. The full candidate build
remains separate. A successful Health permission request AND actual data import on the phone are the
next acceptance checks; do not describe this compatibility repack as the completed Woop release.
The owner has now reported that Health permission was granted and actual Apple Watch data imported
successfully on the free SideStore setup. Treat that as a user-confirmed compatibility result and
preserve the signing/provisioning route during the redesign; it does not verify unrelated new UI code.
The new preparation step's codesign verification runs on macOS CI; local Linux can check shell syntax
but cannot validate iOS code signing or the user's installation.

Without direct HealthKit access, core WHOOP Bluetooth collection and on-device analysis remain separate
from Apple Health. Existing Health export ZIP import and `ShortcutHealthImport` provide alternative
input paths; `ShortcutHealthExport` sends strap data in the other direction. Shortcuts require setup,
permissions and execution and must not be presented as a continuous live Watch sensor connection.

## Reference layout expansion

Analysis migration required: no. The iPhone redesign now applies a shared dark canvas, flat reference
card surfaces and reference header typography across screens. A five-item black navigation bar keeps
Home, Today, Activity, Healthspan and More, including the existing navigation stacks and reselect
behavior. Home has a floating quick-action button and full-width activity rows; activity detail adds a
strain hero using the existing recorded value. New/unconfigured iPhone installs display effort on the
0–21 axis; explicit saved preferences and canonical stored values are retained.

`WoopUIReview` is a separate simulator UI-test scheme. Its workflow checks tab selection and the Home
quick-action entry, and captures seven empty-store screens without generating health data. Simulator
captures are review evidence, not a claim of pixel equality with the supplied populated screenshot.
The current environment lacks Xcode/Swift; Apple compilation and UI execution require the macOS jobs.

The public [WHOOP App Store gallery](https://apps.apple.com/us/app/whoop/id933944389) was also inspected
(version 5.77.0 in the public lookup response). Its Healthspan presentation uses a circular particle
orb and pace scale. The reference UI now draws an independent static orb around the existing resolved
Healthspan age and uses the existing pace slider. Particles are decorative, never data, and render only
with an actual Healthspan result. Missing-input gates, basis disclosures, weekly history and calculations
are retained. No App Store artwork or third-party font is included in the app. The supplied Home screenshot
remains the Home layout reference; newer marketing images do not replace it. Analysis migration required: no.

A follow-up shared-surface audit found that `FrostedCardSurface` still used the old raised palette even
when the reference environment was enabled. It now follows the reference card fill and omits decorative
domain washes and rims in that mode. State-card tints and increased-contrast rims remain. This reaches
legacy detail cards and sheets through the existing shared component without changing their content
or data. UI navigation verification now opens the actual Start Activity picker from Home quick actions.
Analysis migration required: no.
