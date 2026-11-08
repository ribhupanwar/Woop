# Reference UI update — 2026-11-08

Analysis migration required: no. This change reorganizes presentation and navigation; it does not
change stored inputs, scoring formulas, the analysis recipe, or BLE commands.

## References

- Owner-supplied iPhone screenshots of Home, Health Monitor, Stress Monitor and Health, received
  2026-11-08. These take precedence over older Home experiments.
- DSTA `analysis/whoop-5-75-0-ipa-ui` at `034ba05ba78eb43319552e624a82abee7d7929ae`, and the existing
  [Woop static audit](https://github.com/ribhupanwar/Woop/blob/audit/whoop-5-75-0-ui-parity/docs/reverse-engineering/whoop-5.75.0-ui-audit.md).
  Static resource inventory establishes screen roles; it does not recover source or certify geometry.
- [WHOOP Home guide](https://www.whoop.com/us/en/thelocker/the-all-new-whoop-home-screen/)
- [WHOOP navigation guide](https://support.whoop.com/s/article/Navigating-the-WHOOP-Mobile-App?language=en_US)
- [WHOOP Health Monitor guide](https://support.whoop.com/s/article/WHOOP-Health-Monitor-Report?language=en_US)
- [WHOOP Stress Monitor guide](https://support.whoop.com/s/article/Get-to-Know-the-Stress-Monitor?language=en_US)

No proprietary font, artwork, executable code or decompiled implementation is included. Existing
StrandFont and font registrations are preserved. The separate reference roles use Apple's preinstalled
DIN Alternate Bold for scores and metrics, and Avenir Next for text. These approximate the reference
families; they are not claims of identical DINPro/Proxima Nova metrics.

DSTA artifact `13158456060` was downloaded and its ZIP SHA-256 verified as
`6718dfa73c6a130112dbd1ab9315c1c6fec509c2fbb36fddd51a7053b3649b26`. Its resource inventory confirms
DINPro Regular/Medium/Bold and Proxima Nova Regular/Semibold/Bold in the app, alongside Readex Pro.
Only metadata was inspected; no font binary was extracted or added to Woop. Apple documents DIN
Alternate in its [system font inventory](https://developer.apple.com/fonts/system-fonts/).

## Implemented presentation

- Compact Home avatar/date/wordmark and smaller Sleep/Recovery/Strain rings. Source provenance and
  carried Recovery captions remain visible.
- Health Monitor and Stress Monitor entries immediately below the rings. Missing vital signs never
  turn into a five-of-five success; current intraday stress is identified by its recorded bucket time,
  and a daily fallback is labeled separately.
- My Day contains a quick-action button, a local Daily Outlook summary and an activities card whose
  Add Activity and Start Activity controls live inside the card. Both controls retain the existing
  editor/recorder flows, including re-presenting a running workout.
- Tonight's Sleep reads the same gated NextStrapAlarm resolver as Alarms. Its planned bedtime subtracts
  the existing configured sleep-need duration from that fire, rather than inventing an enabled alarm
  or a new sleep recommendation. The button opens the real alarm editor.
- Journal history reads actual native-journal days. The Plan entry opens existing goals. Customizable
  dashboard rows retain their persisted selection and metric routes. Additional prior dashboard
  surfaces remain available under More dashboard sections.
- Weekly zone rows reuse imported workout zone splits, otherwise source-specific recorded HR and the
  profile's existing zone resolver. They describe recorded workouts, not all-day wear coverage.
- Home stress history reuses StressDayCurve and shows an empty state when no scored timeline exists.
  Seven-day Strain/Recovery uses stored daily values, with missing days splitting the lines.
- Health replaces the former Healthspan-only tab, keeping Healthspan and adding both monitor routes.
  Activity and More remain available; Today is consolidated into Home.
- Health Monitor uses live HR and a two-column five-vital grid, with source/baseline/missing-data
  captions and a share action for the current readings. Extra existing health insights remain in a
  disclosure. Stress uses the existing 0–3 score and waking-hour timeline in an arc-and-chart layout.

## Follow-up from simulator evidence

The previous source's UI artifact (`42432058659`, artifact `13598399038`) showed the floating Home
quick-action target at y=850...904 and the custom tab bar beginning at y=872. The new My Day header
owns that action instead, so it cannot sit under the tab bar. The same simulator evidence showed
light-resolved black text on the permanently dark reference canvas. The iPhone scene now requests
dark appearance at the outer presentation boundary, rather than relying on a nested preference that
can be overridden by the scene. This intentionally fixes the reference iPhone appearance to dark;
macOS is unchanged.

The reference navigation now uses a floating material bar with a separate Coach entry that opens
setup when the feature is off. It does not activate the feature. Scrolled Home keeps a compact pillar
strip. The Healthspan empty state uses an original decorative calibration sphere with no synthetic age.

Home and Health summaries use the monitor's temperature preference and HRV over-count caveat inputs,
so an unverified vital cannot become a five-of-five healthy summary. Journal displays a Monday–Sunday
week, and the seven-day chart uses existing civil-day helpers to avoid DST-dependent duplicated dates.

## Validation and remaining comparison

Local Swift grammar parsing, YAML parsing and `git diff --check` are source checks. They do not replace
Xcode type checking, app compilation, simulator interaction or device validation. The branch workflows
run package/macOS validation, the unsigned device archive and empty-store navigation/screenshots.

The priority button/tab IPA is a separate immutable source commit:
`4b18e7c4ba20cae10d714d0c8e90d4b0d4d3b822`, run `42433386209`.

This update is not a zero-difference certification. Paired populated screenshots, exact font metrics,
scroll/header transitions and physical-device states still need comparison. The current local stress
engine scores waking hours; it does not supply sleep-stress duration or reference-style total-day/
weekday comparisons. Those values are not fabricated. Blood-pressure estimates, proprietary Advanced
Labs and a server-backed Community are not implemented by this presentation change. The health share
is a text report of current readings, not WHOOP's 30/180-day PDF service.
