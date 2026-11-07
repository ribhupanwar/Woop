# Running and gym capture readiness

Analysis migration required: no. Source audit only; this is not a successful outdoor/device test.

The owner uses an Apple Watch Ultra 1 LTE and a WHOOP band. Woop Lite excludes the companion Watch
app, so it cannot silently start an independent Woop GPS recorder on the Watch. A completed workout
and route recorded by the Watch can be imported through the phone's authorized HealthKit sync. A
band-only automatic detection has no route unless another device actually recorded one. The free
SideStore compatibility build requested basic HealthKit, not background-delivery entitlement; foreground
sync/data import is user-confirmed, continuous suspended-app Watch ingestion is not verified.

## Existing phone GPS path inspected

- Running defaults to GPS on unless the wearer saved another choice; indoor activities keep GPS off.
- The recorder uses Core Location fitness updates, an iOS background activity session and the declared
  location background mode. It retains location permission/error states rather than treating no fixes as zero motion.
- Accuracy, timestamps, sport-specific speed ceilings, outliers and signal gaps are filtered before
  distance is accumulated. Unmeasured gaps and pauses start segments rather than drawing a fabricated leg.
- Route points retain timestamps and accuracy. Journal/restore and final route persistence preserve
  segment boundaries; imports request associated HealthKit workout-route samples separately.
- GPS auto-pause uses sustained stopped/moving observations. A manual pause cannot auto-resume.

Relevant existing regression suites: `GpsRouteMathTests`, `ActiveRouteJournalTests`,
`WorkoutFeedbackTests`, and `RouteExporterTests`. These cover stored/algorithmic behavior and must run
on the build toolchain; source inspection does not substitute for their results. They cannot verify a
real GPS fix, locked-screen delivery or a user's final signed IPA.

## Required outdoor acceptance

Record Outdoor Run on the Watch when running without the phone. After Watch-to-phone Health sync,
verify one Woop session with correct start/end, route, plausible distance and pace, source attribution,
and no duplicate band-detection entry. With phone recording, test precise location, initial GPS lock,
a locked-screen stretch, a stop/resume, route continuity and saved distance. Never fill a missing route
with a mock polyline. The WHOOP-versus-Woop historical HR/calorie comparison still needs matching raw
recording windows; arbitrary correction constants are not an accuracy fix.

## Runner and gym priorities

Keep GPS/time/HR source consistency and duplicate handling ahead of new scores. Existing running splits,
cardio-load evidence, recovery and strength session/sets/history remain accessible. Automatic exertion
logging does not identify every lift or count trustworthy sets/reps from heart rate alone. Dedicated
HR drift, race prediction and completely automatic dance/gym classification need separate validated
implementations before they can be claimed. The linked VO2 article review is in `VO2_PATENT_RESEARCH.md`.
