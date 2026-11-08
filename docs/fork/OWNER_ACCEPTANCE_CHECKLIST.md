# Owner acceptance checklist

This is the durable scope for the consolidated release, not a declaration that every feature is finished.
“Code present” requires current-head compile/test evidence and device acceptance before release sign-off.
Analysis migration required: no for the currently committed changes.

| Owner request | Current implementation / remaining gate |
| --- | --- |
| Reference Home layout | Header, rings, full-width timeline, floating action and dark palette present; populated screenshot comparison open. |
| Complete UI, not only colors | Five-tab shell, shared surfaces, detail styling and Healthspan orb present; all destinations/sheets require visual review. |
| Home / Today / Activity / Healthspan / More | Navigation code and simulator checks added; current run pending. |
| Woop identity | Own wordmark, system fonts and independently drawn visuals; no third-party artwork bundled. |
| No invented health numbers | Missing values stay missing; decorative particles do not represent measurements. |
| Selected-day activities in time order | Day-window and stable ascending sort implemented; DST/midnight regression coverage added. |
| Add Activity / Start Activity | Existing manual editor and shared recorder reachable; UI test opens recorder picker. |
| Automatically save detected activity | New separate opt-in setting; after activation, settled eligible candidates become editable detector rows. Tests pending. |
| Automatically recognise every sport/dance | Not implemented. Locomotion uses available strap running/walking classes; HR-only spans remain generic Activity. |
| Fix an incorrect activity name | Existing full catalogue editor plus detected-row relabel; Dancing added to quick choices. Device acceptance open. |
| 101 built-in sports | Existing shared catalogue supports running, gym, dance and many more; discovery aliases added without changing stored keys. |
| No duplicates | Existing source-aware dedup plus automatic-save overlap/import/dismissal/answer guards; regression tests added. |
| Respect corrections/deletions | Automatic rows retain detector provenance; edits become wearer input and dismiss original spans. Owner namespace and HR resolver updated. |
| WHOOP band HR / live strain / recovery | Existing collection and independent local analysis retained; not equivalent to proprietary WHOOP algorithms. |
| Sleep / sleep quality / regularity | Existing sleep analysis and reference hero retained; real-data/device review open. |
| Oura concepts / trends | Existing protocol and analytics components are not proof of complete Oura integration. Source-by-source verification remains required. |
| Activity balance / long-term health trends | Existing surfaces retained; complete feature/source acceptance remains open. |
| Healthspan age / aging pace | Existing input-gated engine retained and reference visual added; no number shown without a resolved result. |
| VO2 max / cardiovascular fitness | Dated lab values and authorized Apple Cardio Fitness remain the trusted-source path. Experimental estimates stay separate. |
| Linked WHOOP VO2 patent method | Article reviewed; no reproducible coefficients/model verified. No invented implementation. See `VO2_PATENT_RESEARCH.md`. |
| Running GPS / route / pace / HR charts | Phone capture and Watch HealthKit route import exist; real outdoor/locked-screen/saved-route acceptance required. |
| Auto GPS without phone | Needs a real Watch-recorded route. Lite has no Woop Watch companion; a band-only detected activity cannot reconstruct missing GPS. |
| Pause / resume / route persistence | Existing signal/segment/journal logic and regression suites inspected; physical-device test open. |
| HR drift / cadence / efficiency / race predictions | Existing efficiency and supported cadence data are not complete dedicated drift/race-prediction features. Remaining runner scope open. |
| Daily gym / strength sessions | Existing sets/session/history retained. HR-only detection does not identify every lift or count verified reps. |
| Training load / recovery adjustments | Existing cardio/recovery surfaces retained; automatic saves queue a non-reused follow-up analysis. Complete decision acceptance open. |
| Daily AI coaching / 1:45 half-marathon progress | Full goal-specific daily coaching and free/offline capability must be verified; not declared complete. |
| WHOOP versus Woop run discrepancies | Stale detail-HR resolver repaired. Exact historical comparison remains unproven without matched windows/samples; no arbitrary matching factors. |
| HealthKit on free SideStore | Owner confirmed permission and actual Watch data on earlier compatibility IPA. Preserve same signing route in candidate. |
| Slow sync | Home/Today now request actual data; bounded manual Health reads and coalesced pulls added. Radio throughput and physical timing remain unmeasured. |
| Home pull-to-refresh | Shared strap request + local refresh + recent Health import + visible refresh implemented; concurrent-pull regression test added. |
| Source/provenance transparency | Imports keep origin; automatic detector output is never called user-confirmed training evidence. |
| IPA size/performance | Lite trims optional model and extensions; final candidate artifact size/startup/scroll/battery checks open. |
| Consolidated installable release | Candidate code pushed to PR 6; latest macOS validation, screenshot review and IPA packaging must pass. |
| No repeated reminders | This checklist and the linked audit documents retain the complete requested scope. |

Acceptance evidence must identify source commit, build, device/OS, recorded data source and screenshot
state. An empty simulator screenshot does not certify populated-screen pixel equality, Bluetooth sync
speed, HealthKit provisioning, background delivery or GPS accuracy.

## Latest owner priority

Complete the reference UI/layout review first, then return to additional integrations. Running and daily
gym use, trustworthy HRV/RHR and independent data capture remain priorities. Direct Strava upload is
requested as a later optional connection: official upload/auth documentation was reviewed; existing FIT
export is available, but direct OAuth/upload is not shipped. An initial request-builder draft is preserved
outside the app checkout at `/workspace/work/strava-draft/StravaRequests.swift` and is not compiled or
advertised as working. No user credentials were requested or external workout uploads performed.

## Monitor and navigation correction batch

Analysis migration required: no. Adds Home Health/Stress Monitor links, flat vital tiles and a local
health-report share action. Health coverage counts only finite, verified readings on the selected day;
partial coverage cannot show 5/5. Stress remains explicitly a daily estimate, not WHOOP live stress.
Healthspan now links to the existing WHOOP MG ECG capture sheet with its consent and experimental
feature gates preserved; no measurement starts automatically. Hardware capture remains unverified.

Simulator review of commit 0e12a20 exposed a light Today palette, an obstructing arrangement hint and
a floating action button overlapping navigation. The correction forces reference dark appearance,
retains customization without the automatic hint, and reserves physical space for bottom navigation
and the active-session accessory. Start Activity has explicit readable foreground/background colors.
The full-tab animation and reference vital-tile entrance animations were removed; physical-device frame
timing remains to be measured. Added monitor coverage tests and navigation/ECG UI checks.

The owner corrected the detection settings report: both switches had been off and are now enabled.
Future eligible activities need on-band data, sync and analysis; this is not evidence that all activity
types are classified automatically. No physiological formula or historical score was changed.

The f147ac4 build failed on LocalizedStringKey.uppercased in SleepView; use Text.textCase instead.
The current batch requires fresh macOS/iOS compilation and screenshot review before release acceptance.
