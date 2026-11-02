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
