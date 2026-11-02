# WHOOP 5.75.0 UI parity audit

Source: pinned WHOOP iOS 5.75.0 release IPA, bundle `com.whoop.iphone`, build `738478`.
The archive and executable were inspected statically. The extracted report is a reference for clean-room recreation only; do not copy proprietary executable code, images, logos, or font files.

## Verified extraction inventory

- 4,509 UI/resource inventory records.
- 3,733 localized `.strings` files, 244 `.stringsdict` files.
- 180 NIB files, 193 plist files, 86 JSON resources.
- 38 asset catalogs, 26 TTF files, 9 OTF files.
- Key Home resources include `Home.storyboardc`, `HomeView`, `HomeMyDashboardView`, Recovery, Sleep, Strain and Health Monitor strings.
- WHOOP bundles DINPro Regular/Medium/Bold font files. These are proprietary and must not be copied into Woop. Recreate the typographic character with system/licensed faces.

## Woop implementation map

| WHOOP surface | Woop starting point |
|---|---|
| Today / Home overview | `Strand/Screens/TodayView.swift`, `Strand/Liquid/LiquidTodayView.swift` |
| Recovery / Sleep / Strain overview | `Strand/Screens/OverviewDashboardView.swift`, `Strand/Screens/TrendsDashboardView.swift` |
| Sleep details | `Strand/Screens/SleepView.swift` |
| Health metrics | `Strand/Screens/HealthView.swift` |
| Activity / strain detail | `Strand/Screens/TrainingLoadView.swift` |
| HRV reading | `Strand/Screens/HRVSnapshotView.swift` |
| iPhone navigation | `StrandiOS/App/RootTabView.swift` |
| Typography system | `Packages/StrandDesign/Sources/StrandDesign/Typography.swift` |

## Porting rules

1. Match information hierarchy, spacing, card geometry, ring proportions, labels, tab navigation and interaction states against the 5.75.0 reference.
2. Use existing Woop repository models and real stored strap data. Never fill a missing value with a decorative/fake score.
3. Keep BLE, packet decoding, persistence, analytics and workout recording unchanged during UI-only work.
4. Add a dedicated WHOOP-like typography layer using system/licensed fonts; do not replace unrelated app typography globally.
5. Preserve accessibility, Dynamic Type, localization and empty/calibrating/disconnected states.
6. Record `Analysis migration required: no` for UI-only changes.
7. Before pushing app/package code, run `Tools/local-tests.sh` on the committed tree. Verify iOS app compilation in macOS CI; do not call a compile-only check a device test.

## Current status

- Static IPA extraction: complete.
- Screen-by-screen visual audit: in progress; static extraction does not recover SwiftUI source or all runtime constraints.
- Woop implementation: clean-room typography pass is underway on the WHOOP-reference dashboard branch. The dedicated typography roles are applied to Today, Overview, Sleep, Health, Training Load and HRV snapshot labels/selected metrics; Overview ring labels and Sleep hero/stage labels are aligned. Overview metric rings were increased from 74pt to 80pt, and the Sleep hypnogram's stage/time axes now use compact reference label typography. This remains a partial presentation pass, not a complete screen replica.
- Remaining visual work: Recovery hero/card geometry, full Sleep chart/detail comparison against device screenshots, tab/navigation parity, and screenshot-based device review.
- Validation still required: run `Tools/local-tests.sh` on the branch and compile/install on macOS/iOS; no IPA is certified by these source-only commits.


## Recovery surface audit — 2026-11-02

A source-only pass traced the Overview Recovery entry without changing app code:

- `Strand/Screens/OverviewDashboardView.swift` resolves the displayed value through `ChargeDisplay.resolve(days:displayDay:selectedDayKey:isToday:)`; the ring reads the resolved `pct`, and carried scores retain their provenance caption. Calibration and no-data remain distinct empty states.
- The Overview Recovery row is an 80pt compact metric ring in the three-metric stack and navigates to the WHOOP-sourced `recovery` metric route. It is not the standalone Recovery detail/hero screen.
- `Packages/StrandDesign/Sources/StrandDesign/RecoveryRing.swift` supports a 240pt default hero gauge, but also layers Woop's own NOOP wordmark and glyph core behavior. `BevelGauge.swift` owns the shared 240-degree arc, track, center readout and tip.
- The current source therefore proves that a reusable large Recovery gauge exists; it does **not** prove that the dedicated Recovery detail screen matches WHOOP 5.75.0. The exact detail layout, surrounding cards, and spacing still require a user-provided WHOOP Recovery screenshot or another verified visual reference.
- No Swift source, sensor pipeline, score logic, or app behavior was changed in this audit. This is documentation only; it is not a build or device-validation result.


## Recovery detail navigation audit — 2026-11-02

Followed the Overview Recovery tap through the production route:

- `OverviewDashboardView` wraps its 80pt Recovery row in `NavigationLink(value: TabRoute.metricSourced(key: "recovery", source: Repository.whoopSource))`.
- `Strand/App/TabRoute.swift` resolves that exact catalog key/source to `MetricDetailView(metric: m)`.
- `MetricDetailView` is a generic metric dossier: title + range selector, a 188pt `LiquidVessel` for 0–100 metrics, latest value/date, history `ChartCard`, statistics, readings and correlation content. The Recovery route does not instantiate `RecoveryRing`.
- The detail hero is currently driven by the latest point in the selected metric's history, while the Overview ring uses `ChargeDisplay.resolve` (including calibration/carry provenance). These are separate presentation paths; do not assume the generic detail hero reproduces the Overview carry/calibration state.
- This confirms a concrete implementation distinction, not a pixel-level WHOOP mismatch: no verified WHOOP Recovery detail screenshot is present in the repository to ground exact section order, spacing, or chart/card styling.
- No app source, route, metric calculation, BLE, or stored data was changed. This audit adds documentation only; it does not constitute an Xcode build or device test.


## Recovery data-source audit — 2026-11-02

A further read-only pass traced the score and supporting-series contracts before proposing a dedicated detail view:

- `ChargeDisplay.resolve` is a presentation-state resolver, not a scoring engine. It selects the selected day's real `DailyMetric.recovery`, an eligible prior scored day, a calibration state, or no-data; it never creates a score.
- `RecoveryScorer.recovery(...)` requires a usable personal HRV baseline and a real nightly HRV input. RHR, respiration, Rest quality, skin-temperature deviation, recovery-index slope and prior-day Effort are optional terms; absent optional drivers are dropped rather than replaced with synthetic values. The scorer's cold-start gate returns nil when the HRV baseline is not usable.
- The metric catalog exposes separate WHOOP-source series for `recovery`, `hrv`, `rhr`, `resp_rate`, `spo2` and `skin_temp`. The source label alone is not a guarantee that every series has a reading for every day.
- `Repository.exploreSeries` is the established history read path. Its WHOOP-source resolution can combine imported and computed source rows and a daily-column fallback; a dedicated detail should use this repository resolver rather than querying one raw store partition or assuming the catalog key maps one-to-one to a physical table.
- Supporting HRV/RHR values must be date-aligned to the score's actual scored night. The repository has a separate recovery-independent overnight-vitals carry; that selector is intentionally not a source for Charge/Effort/Rest. A detail must preserve this separation and label any carried value/provenance rather than silently pairing today's score with an unrelated prior vital.

**Safe implementation boundary:** the existing model contracts support a dedicated Recovery presentation, but the next implementation must first confirm the exact scored-day selection and date alignment for each supporting series. No source/data behavior was changed in this audit. Documentation only; no Xcode build or device test was run.


## Recovery detail implementation contract — 2026-11-02

The follow-up source trace located the generic detail implementation inside `Strand/Screens/MetricExplorerView.swift` (it is not a standalone `MetricDetailView.swift` file):

- `MetricDetailView.load()` phase 1 loads the selected metric's values with `Repository.exploreSeries(key:source:)`. It separately loads `Repository.resolvedSeries(key:source:)` to attribute each daily point to the source that supplied it. The two paths are intentionally not interchangeable: the plotted history uses the established Explore series; provenance comes from the resolved points.
- The generic detail then derives its visible range relative to the latest actual point, and builds its hero/statistics/readings/correlation sections from that metric series. Its 0–100 hero is a generic `LiquidVessel`, not the dedicated Recovery gauge.
- The WHOOP Recovery overview entry currently resolves the catalog descriptor `recovery / my-whoop` and lands in that generic dossier. The source file containing the generic detail is `Strand/Screens/MetricExplorerView.swift`; navigation remains declared in `Strand/App/TabRoute.swift`.
- The repository's `DailyMetric` history is oldest-to-newest and has explicit daily columns. `Repository.lastVitalsDay`, `lastHrvDay`, and `lastRestingHrDay` are carry selectors for current vital cards, not valid shortcuts for joining supporting values to an older Recovery score. The detail must select HRV/RHR by the score's own day first and show a missing value when that night has no corresponding reading.
- The metric catalog's WHOOP-source descriptors are `recovery`, `hrv`, `rhr`, `resp_rate`, `spo2`, and `skin_temp`. Each series must be read through `exploreSeries`; no assumption should be made that every descriptor has a point on the selected score day.

**Implementation sequence:** (1) add a dedicated Recovery route/view while keeping the existing generic dossier available for other metrics; (2) resolve the selected score with the same `ChargeDisplay` rules used by the dashboard; (3) join supporting vitals on the exact scored day, with explicit unavailable/carry provenance states; (4) use `exploreSeries` for chart history and `resolvedSeries` only for source attribution; (5) add tests for scored, carried, calibrating, no-data, and missing-vital combinations. Exact visual geometry still needs a WHOOP Recovery detail screenshot; do not claim pixel parity without that reference.

This commit records the verified code paths and safe implementation contract only. It does not change app source, BLE, scoring, persistence, or sensor behavior, and no Xcode build/device test was run.


## Recovery data join contract — 2026-11-02

The underlying row model was verified in `Packages/WhoopStore/Sources/WhoopStore/MetricsCache.swift`:

- `DailyMetric` carries `day`, `recovery`, `avgHrv`, `restingHr`, `respRateBpm`, `spo2Pct`, `skinTempDevC`, `skinTempC`, and the sleep/activity fields as nullable values. These are real daily observations, not presentation placeholders.
- The model documents its `days` ordering as oldest-to-newest. Date matching for a Recovery detail can therefore use the selected scored row's `day` and must not substitute the latest vital row when that exact day is missing.
- The generic detail's history/provenance split is confirmed in `Strand/Screens/MetricExplorerView.swift`: values come from `repo.exploreSeries`, while `repo.resolvedSeries` supplies per-day source attribution. The generic screen currently renders the 0–100 score as a `LiquidVessel` and uses its generic chart/statistics stack.
- `RecoveryRing` is a reusable large gauge, but it includes Woop branding layers and is not currently called by `MetricDetailView`. Reuse must be deliberate; do not mistake its existing preview for a production Recovery detail.

**Next UI implementation boundary:** add the dedicated Recovery route/view without changing `RecoveryScorer`, `ChargeDisplay`, BLE, or persistence. The view must keep the four truthful score states (scored, carried with date caption, calibrating, no data), align HRV/RHR to the selected score day, and show missing values as missing. Continue using the generic metric detail for all non-Recovery metrics. Until a WHOOP Recovery screenshot is available, match the established Woop design language and label the result as a structural implementation—not pixel-verified parity.

This additional audit is documentation-only; no app source or runtime behavior changed, and no Xcode build/device test was run.

## Recovery detail implementation — 2026-11-02

The first app-source implementation is now present on the parity branch:

- Added `Strand/Screens/RecoveryDetailView.swift` and routed both bare Recovery metric routes and the WHOOP-sourced Recovery route to it. The generic metric dossier remains the destination for other metrics.
- The hero uses `ChargeDisplay.resolve`, preserving scored, carried, calibrating and no-data states. A carried score retains its existing provenance caption; no empty state is represented as zero.
- HRV and resting HR are displayed only from the exact `DailyMetric` row selected as the scored night. The UI explicitly says the readings are not carried across nights.
- Added a compact recent-history view from recorded `DailyMetric.recovery` values only. The WHOOP source data path and score engine are unchanged.
- The new file is included by the iOS XcodeGen target's existing `Strand` source directory, so no project-file registration was needed.

**Validation status:** source and route were reviewed against the existing resolver/model APIs, but this environment has not run `Tools/local-tests.sh`, Xcode compilation, simulator, or device screenshot QA. This is an implementation milestone, not a completed WHOOP visual replica or verified IPA. Exact Recovery screen geometry still needs a trusted reference screenshot for pixel-level comparison.

## Sleep and navigation UI audit — 2026-11-02

### Sleep surface findings

- `SleepView` already pins a night-performance hero and date navigation above its reorderable analytical sections. Its score and source badge are derived from the displayed `Night`; no separate UI-side score is needed.
- With timestamped intervals, the stage card supports the WHOOP-style stepped hypnogram (`filled` / `ribbon`) as well as the detailed per-stage timeline. When intervals cannot be reconstructed, it falls back to the proportional stage bar rather than inventing a timeline.
- The detailed stage rows already use compact reference labels, colour-coded percentages, duration bars, and tap-to-highlight interaction. The remaining gap is visual comparison against a real WHOOP screenshot/device capture, not absence of a hypnogram implementation.
- The chart-style preference deliberately defaults to `classic` and is shared with Android. This pass does not silently override a stored user preference or create an iOS-only default divergence.

### iPhone navigation findings

- `RootTabView` uses the native iOS `TabView` with Today, Trends, Training, Sleep and More. Each primary tab owns a bound `NavigationStack`; this preserves independent back stacks and root re-tap behavior.
- The previous custom floating tab bar was replaced by native navigation because the app's floating Coach action moved to the header. The native bar preserves safe-area handling, Dynamic Type and iOS 26 Liquid Glass.
- No tab labels/icons were changed without a WHOOP 5.75 screenshot to ground the comparison. Tab order and icon parity remain a screenshot-review item.

### Recovery detail follow-up

The dedicated Recovery screen now presents HRV, resting HR, respiratory rate and skin-temperature deviation from the exact scored-night row. Missing fields remain dashes; none are carried from another night. The new text uses the clean-room `WhoopReferenceFont` roles already used by the parity pass. No scorer, BLE decoder, or data persistence code changed.

**Validation remains pending:** the branch's `Tools/local-tests.sh` requires macOS, XcodeGen and Xcode for the app leg. No Xcode build, simulator/device screenshot, or IPA was produced in this session.

### Sleep typography follow-up — 2026-11-02
- The Sleep-performance hero heading now uses the compact reference heading role; the night navigator title and duration chip use the reference heading/label roles as well.
- This is a typography-only presentation adjustment. The sleep score, sleep-night selection, chart-style preference, hypnogram intervals, stage totals, motion trace, and sleep persistence are unchanged.
- Navigation review confirms the current iPhone shell has five native tabs (Today, Trends, Training, Sleep, More), each with its own bound navigation stack. Without a matching WHOOP 5.75 screenshot, changing tab order or iconography would be speculative, so those remain unchanged pending visual QA.
- Validation remains source review only: no Xcode build, simulator run, or device screenshot was available in this environment.


## Extracted IPA artifact re-inspection — 2026-11-02

The previously generated DSTA Actions artifact was recovered and inspected directly; no user screenshots were needed to continue the static comparison.

- Source: DSTA workflow run [41341431589](https://github.com/ribhupanwar/dsta/actions/runs/41341431589), artifact `whoop-5.75.0-ipa-ui-reference` (artifact ID `13098150114`), pinned WHOOP iOS 5.75.0 / build 738478. The artifact contains 2,873 extracted files. Its extraction log records 6,706 files in the app bundle.
- The artifact contains localized strings, NIB class/wiring reports, executable strings/symbols, Objective-C metadata and asset-catalog metadata. It does not contain the compiled SwiftUI source or the actual pixels for the `OverviewScreenshot`, `RecoveryScreenshot`, `SleepScreenshot` and `StrainScreenshot` asset renditions; those image entries are metadata only (315×683 at 3x). Therefore it supports structural and copy comparison, not pixel-perfect screen measurement.
- WHOOP's Home onboarding copy explicitly describes a daily dashboard with swipe access to the Sleep, Recovery and Strain pillars.
- `OverviewGauge` strings expose the pillar labels Recovery, Sleep, Strain, HRV and Performance, plus explicit empty-value forms (`--%`, `--`, Not Available).
- Recovery contributor strings identify HRV, Resting Heart Rate, Respiratory Rate and Sleep Performance. Woop's Recovery detail previously showed skin temperature in the fourth slot; that slot is now same-day Sleep Performance, resolved through `DashboardRestScore.value(day:days:importedSleep:)`, the same imported-first/on-device composite resolver used by Sleep and Today. It never borrows a score from another date. The section is labelled Recovery contributors.
- Sleep Performance strings expose the title, Hours of Sleep, Sleep Needed and Share. Woop's existing Sleep view already has a per-night performance score, sleep-stage timeline/hypnogram, and sleep-need/debt sections; no duplicate Sleep implementation was added.
- Navigation symbols identify `MainViewTabBarController`, `MainViewTabNavigationRouter`, `BottomNavigationType`, `TabBarConfiguration` and `TabBarConfigurationService`. The BFF tab-bar adapter accepts Strain, Health, Community, Menu and Shop controllers, while the actual tab configuration is fetched/cached dynamically. Static extraction does not reveal the user's runtime tab payload, so changing Woop's five tab labels/order based on an assumed fixed WHOOP configuration would be guesswork. Keep the existing five independent Woop navigation stacks until a grounded runtime configuration is available.
- The Home storyboard NIB is only a `HomeViewController` host/root view; the main pillar/dashboard UI is represented by compiled SwiftUI symbols and strings, not recoverable storyboard constraints.

**Code change from this re-inspection:** `Strand/Screens/RecoveryDetailView.swift` now shows the four WHOOP-aligned contributors (HRV, Resting HR, Respiratory Rate, Sleep Performance) with all values aligned to the selected scored-night date. Recovery scoring, BLE, persistence and sensor decoding are unchanged.

**Remaining validation:** run `Tools/local-tests.sh`, compile the iOS target on macOS, then install and capture a device screenshot for visual QA. The extracted metadata alone cannot certify pixel parity or an IPA.


## Current source re-verification — 2026-11-02

The earlier Recovery navigation audit above describes the route state at the time of that audit and is now superseded by the current branch source:

- `Strand/App/TabRoute.swift` now sends both `.metric("recovery")` and the WHOOP-sourced `.metricSourced(key: "recovery", source: Repository.whoopSource)` route to `RecoveryDetailView()`.
- Other sourced metrics continue to use `MetricDetailView`, preserving their exact catalog-source resolution.
- `RecoveryDetailView.load()` resolves the score through `ChargeDisplay.resolve`, chooses the matching scored night for contributors, and keeps the recent recorded recovery history separate from the hero state.
- The current route source therefore confirms that the dedicated Recovery view is wired into the route switch. It does not establish that every entry point is registered correctly in every navigation shell, nor does it establish pixel-level parity.
- The repository has analytics and dashboard recovery tests, but no dedicated `RecoveryDetailView` UI test file was found in the current branch tree. Route/state UI coverage remains a follow-up.
- This source audit was performed through GitHub's text/API view; the reference ZIP was not unpacked or visually inspected in this pass. No Xcode build, simulator run, install, or device QA was performed.

The remaining evidence-based work is to add focused route/state coverage, run `Tools/local-tests.sh` in a supported macOS environment, then compare actual iPhone screenshots for Home, Recovery and Sleep against the extracted reference. Do not label the UI pixel-complete until those checks pass.


## Sleep / Home / tab-shell source audit — 2026-11-02

A read-only pass traced the current visible composition and the controls that can change it:

### Sleep
- The Sleep tab is a primary iOS tab (SleepView) and its hero is pinned; it is not part of the reorderable card list.
- With a resolved night, the top-level sequence is: freshness/deleted/undo context, the full-width Rest hero, alarms entry, optional sleep-goal context, then the saved analytical sections. The analytical default order is Sleep marks, Stages, Body clock, Night detail, Sleep-debt ledger, Stages vs typical, Asleep duration.
- The analytical order and hidden set are persisted separately (sleep.sectionOrder, sleep.hiddenSections). SleepLayoutPrefsTests already pins default order, migration of missing sections, explicit reversible hiding, uniqueness and stable raw keys.
- The actual hero and chart variants depend on the saved chart style, dashboard style, scene-background preferences, selected night offset, and available sleep-session data. A source-only read cannot certify the rendered chart geometry or exact reference colors.

### Home / Overview
- Overview is one selectable Today dashboard style, not a separate tab. Its root pins the header, health alert, active-workout indicator and morning suggestion above the configurable dashboard sections; Plan Today is below them.
- Its Recovery ring uses ChargeDisplay.resolve, so scored/carry/calibration/no-data states are shared with the other Today presentations. The sleep-performance value is resolved from the selected day using imported sleep first, then the daily composite, with the repository series as the freshness fallback.
- The layout has its own saved section order/visibility and compact spacing. The code comments describe a one-screen reference target, but the implementation remains a scroll view and optional/customized sections can extend it.

### iOS tab shell
- Current primary tabs are Today, Trends, Training, Sleep and More, in that order. Each has its own NavigationStack path. Re-tapping the selected tab refreshes; if pushed, it pops to root; if already at root, it sends a scroll-to-top signal.
- This is a five-tab native iOS shell. It is not evidence of WHOOP's exact tab order or iconography; no visual comparison was made in this pass.

### Validation / next implementation boundary
- Sleep layout persistence and dashboard layout state already have focused pure-logic tests. Recovery score-state behavior also has existing DashboardChargeHeroTests; a dedicated SwiftUI navigation/UI test for RecoveryDetailView was not found.
- The next safe code task is focused route/state test coverage, not a broad layout rewrite. Any pixel-level adjustments must be grounded in a rendered WHOOP reference screen and a matching Woop device screenshot.
- This audit changed documentation only. No app source, BLE, sensor decoding, persistence, scoring, or workout behavior changed; no local tests, Xcode build, simulator run, or device QA was executed.


## Follow-up source audit — 2026-11-02 (continued)

The current branch was re-checked after the earlier status notes above. These corrections supersede any stale statements in the preceding audit:

- Dedicated Recovery route coverage **does exist**: `StrandTests/RecoveryRoutePolicyTests.swift` pins the unscoped Recovery route, WHOOP-source-only routing, and negative cases for other metrics/sources. `HeroRingDetailRouteTests.swift` also pins the hero metric keys and catalog uniqueness. The earlier statement that no Recovery route test file was found was incorrect.
- Sleep layout persistence coverage exists in `StrandTests/SleepLayoutPrefsTests.swift`; it pins default order, migration, visibility, uniqueness and raw keys. It does not test rendered typography or chart geometry.
- Current direct typography usage is uneven: `OverviewDashboardView.swift` uses `WhoopReferenceFont` (10 call sites in the inspected source), and `HealthView.swift` has a small scoped pass (1 direct font call plus six reference overlines). `SleepView.swift` currently has **no direct** `WhoopReferenceFont` or `whoopReferenceOverline` calls. Therefore the earlier note that Sleep hero/stage labels were aligned to the dedicated typography layer is not verified by current source and must not be treated as complete.
- `RecoveryDetailView.swift` currently uses the dedicated reference roles and displays HRV, Resting HR, Respiratory Rate and Sleep Performance. The score state still comes from `ChargeDisplay.resolve`; the contributor values are read from the same selected scored-night row.
- The repository tree has no files under `.github/workflows/` on this branch. `Tools/local-tests.sh` is the documented local validation path, but requires macOS, XcodeGen and Xcode. No build/test pass is claimed here.

### Remaining implementation / verification

1. Apply a scoped typography pass to Sleep's pinned hero, night navigator and hypnogram labels using the existing clean-room roles, without changing sleep calculations, stored chart-style preferences, or section ordering.
2. Re-check Health's primary live-HR hero and vital tiles for consistent typography hierarchy; retain existing Health information architecture unless a WHOOP reference proves a different structure.
3. Review the Recovery detail and overview ring as separate screens; keep the exact scored-night data alignment and empty/calibrating/carry states.
4. Run `Tools/local-tests.sh` and the iOS simulator build on macOS. This environment has not executed those commands.
5. Compare same-device WHOOP 5.75 and Woop screenshots before making pixel-level claims. The extracted IPA artifact provides static metadata, not actual screenshot pixels or compiled SwiftUI layout constraints.

This follow-up is a source audit and documentation correction only. No app code, sensor pipeline, scoring, BLE, persistence, or workout behavior was changed by this note.


## Sleep typography implementation — 2026-11-02

A scoped clean-room typography pass was committed to `Strand/Screens/SleepView.swift`:

- Pinned hero: night-relative overline, “Sleep performance” heading, score-state label, and the unscored-night caption now use the existing `WhoopReferenceFont` roles.
- Stage detail: the stage-breakdown overline, stage names, percentage/duration values, and movement-strip caption now use the same scoped reference roles.
- No sleep score calculation, selected-night logic, chart-style preference, hypnogram intervals, stage totals, persistence, BLE, or workout behavior was changed.
- Static source verification confirms these roles are present in the current branch. No Xcode compile, automated test run, simulator render, or screenshot comparison has been performed; the visual result is not yet certified.

This is a targeted typography implementation, not a claim of full Sleep-screen parity.

## Health typography pass — 2026-11-02

A scoped presentation-only typography pass was applied to `Strand/Screens/HealthView.swift`:

- The live heart-rate fallback numeral now uses the dedicated reference score role; its bpm unit uses the compact reference label role.
- Recovery contributor labels, values and state words use the reference label/metric/body roles while retaining their existing layout and fixed value column.
- Vital-sign values and state captions use the reference metric/body roles; all formatters, units, colours, accessibility labels, data sources and nil states are unchanged.
- Static source verification confirms the edited call sites are present and the targeted legacy font calls are absent.

This is a typography consistency pass, not a verified visual match. No Health calculations, live-HR sampling, BLE, persistence, or routing changed. Xcode compilation, simulator/device review and screenshot comparison remain unrun.

## WHOOP 5.75.0 extracted UI reference — artifact review (2026-11-02)

The previously generated GitHub Actions artifact is now retrieved and inspected directly:

- Workflow run: [Inspect WHOOP 5.75.0 IPA UI reference](https://github.com/ribhupanwar/dsta/actions/runs/41341431589), run #2.
- Artifact: `whoop-5.75.0-ipa-ui-reference` (artifact ID `13098150114`; 7.19 MB compressed; SHA-256 `696e1b2896fa4c1fe2dee38c21c74c5df0fa8a250fdbf630500275308f140937`).
- The extraction README identifies the pinned `pulseforge.ipa` release asset as the WHOOP 5.75.0 iOS reference. The archive itself was not included in this small report artifact; the report contains static resource, string, symbol and metadata inventories.
- The downloaded report ZIP contains 2,873 files. Its manifest records 6,708 entries in the original IPA bundle and 4,509 UI/resource inventory records; the bundle identity is `com.whoop.iphone`, version `5.75.0`, build `738478`.
- The report exposes compiled view/model names including `HomeMyDashboardView`, `HomeView`, `OverviewGauge`, `RecoveryDetails`, `SleepPerformance`, `StrainCoachView`, `HealthMonitorView`, `HealthMonitorGridView` and `HealthMonitorMetricView`. These are metadata identifiers, not recovered SwiftUI source.

### Additional reference details confirmed by the extraction

- Home onboarding copy says the Home surface contains daily metrics, activities and weekly trends, and that swiping exposes the Sleep, Recovery and Strain pillars. The Home action button provides activity, journal and workout-library entry points.
- The overview gauge vocabulary is Recovery, Sleep, Strain and HRV. Empty values are represented as `--` / `--%` and “Not Available”; a missing value must not be rendered as zero.
- Dashboard customization uses “Customize Overview”, “Add to Focus Metrics”, a Stats section, Select and Save actions.
- Health Monitor metadata includes a grid/metric-view component family. The extracted metric vocabulary is HRV, RHR, Respiratory Rate, Blood Oxygen (SpO2) and Skin Temperature. The reading-state vocabulary distinguishes no data, calibrating/recalibrating, within/near range, elevated/very elevated and low/very low. The screen also has explicit sleep-data-required and WHOOP 4.0-required states.
- Sleep strings confirm “Sleep Performance”, “Hours of Sleep”, “Sleep Needed”, share action and a dedicated Sleep Needed explanation covering baseline, recent strain, sleep debt and naps.
- Strain Coach strings confirm “Strain Target”, “Training State”, “Activity Strain”, “Current Day Strain”, “Estimated Day Strain”, “Optimal Training”, restorative/optimal/overreaching states and explicit recovery-required / set-goal empty states.
- Main-tab localization contains Home, Health, Coaching, Community, More, Plan, Profile and Shop labels. This is a vocabulary inventory only; it does not establish which tabs are enabled in every account or exact tab order.

### Clean-room implementation applied from this evidence

- `HealthView` now places the existing five-metric strap-vitals grid immediately after the live-HR hero. Woop-only interpretation layers (Fitness Age, Vitality/Body Age, optional rhythm and Recovery contributor analysis) follow the core metric grid. This uses the extracted Health Monitor grid/metric hierarchy without copying proprietary code or assets and does not alter any data, scoring, BLE or persistence logic.
- The report artifact contains no runtime screenshots and no original SwiftUI view source. It supports information architecture and state/copy vocabulary, but cannot prove exact pixel geometry, animation, or tab order. Device screenshot comparison and an iOS build remain outstanding.
