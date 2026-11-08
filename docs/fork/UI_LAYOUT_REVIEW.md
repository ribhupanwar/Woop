# Reference UI review

Analysis migration required: no.

Review scope: Home, Activity, Healthspan, More, Sleep, Recovery, day strain, Health Monitor,
Stress Monitor, workout detail, activity recording entry and ECG entry.

## Evidence and corrections

- The 4b18e7c simulator artifact was downloaded and its eight screenshots visually inspected.
  Sleep, Recovery, strain, More, Healthspan and Activity had low-contrast dark text on dark surfaces.
  Home's automatic arrangement hint obscured content. Start Activity opened its recorder successfully,
  but floating quick actions failed navigation. These are older-build observations, not current passes.
- Commit cf77248 forces the reference appearance at the app root, suppresses the automatic hint,
  reserves bottom-navigation layout space, and adds monitor and ECG navigation checks. Its simulator
  and IPA validation must finish before these corrections can be certified visually.
- Workout detail still used a liquid vessel and animated count-up in reference mode. The follow-up
  uses the shared static blue ring and reference typography, preserving source values and effort scale.
- Home uses a lazy section stack. The reference stress gauge and Healthspan particle orb have no
  periodic animation timer. Whole-tab and reference vital-tile entrance animations were removed.
  This is source inspection, not measured frame timing on an iPhone.

## Acceptance still required

Inspect fresh screenshots of every listed screen, including readable labels, safe-area spacing,
button contrast, tab/FAB separation and chart clipping. Empty simulator state cannot establish populated
layout parity. The owner's supplied screenshots guide Home and monitor composition; equivalent
references are not available for every secondary screen. System typography approximates the supplied
reference and does not establish zero pixel difference. Test scrolling with real history, live HR,
sync in progress and active workout on the owner's device; no zero-lag guarantee is established here.

## Visible-tab work and runner readout

Home dashboard loads, energy/hydration queries and its Health Monitor query now include tab visibility
in their task identity. Hidden Home instances do not start those reads; returning to Home restarts
with the latest data revision, and cancelled requests cannot publish stale results. This reduces
competition with Activity/Healthspan interaction without stopping sync or recording.

On-foot workout details expose average pace alongside distance even when no route points were imported.
It requires a finite positive recorded distance and recorded active duration, and reuses the existing
unit-aware pace formatter. No pace, distance, cadence or GPS points are generated for missing data.
Analysis migration required: no. Device frame timing and populated-screen validation remain open.

## Owner-supplied metric-card reference

Replaces the compact Your Health table with independently drawn full-width metric cards: outline icons,
uppercase labels, large trailing numbers and optional previous-reading comparison. HRV, RHR and steps
comparisons require two finite stored daily readings; arrows indicate direction only, and the comparison
date is explicit. No arbitrary Optimal label, baseline, weekly zone time or strength duration is invented.
Reference defaults include HRV, RHR, steps and VO2; an existing custom metric selection is retained.
Customize opens the existing dashboard editor, and each metric retains its existing detail route.
Cards are static and reuse already-loaded values, with no animation timer or additional queries.
Analysis migration required: no. Fresh screenshot review and app compilation remain required.

## Charts below dashboard metrics

Home now hosts Stress Monitor and Strain & Recovery cards below its metric cards. The intraday card
reuses StressDayCurve caching, background scoring and the gap-preserving gradient line renderer. It
loads only while Home is active and shows no timeline on unsupported historical selections. Seven-day
strain/recovery uses stored daily rows, separate 0-21 and percentage axes, labels and recovery colors.
Missing days split lines instead of creating interpolated readings. No sample data or timer is added.
Analysis migration required: no. New chart compilation and screenshot validation remain pending.
