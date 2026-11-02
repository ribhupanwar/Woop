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
