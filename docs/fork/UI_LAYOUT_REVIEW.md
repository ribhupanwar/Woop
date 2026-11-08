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
