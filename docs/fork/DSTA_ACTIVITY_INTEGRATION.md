# DSTA activity and sleep integration audit

Analysis migration required: no.

## Evidence reviewed

- DSTA main `bdee9cd087a2dd8564a7e60ac218cb2c010ebbd0`, including
  `PulseForge/WhoopBluetoothManager.swift` and the workout UI.
- Activity archive audit branch `ea291738b9cebb3ec5efda00f867e4480098abd0` and its
  [successful metadata report](https://github.com/ribhupanwar/dsta/actions/runs/41566744266),
  artifact `13199816755`.
- DSTA `docs/WHOOP-archive-findings.md`, which explicitly marks experimental motion decoding and
  classification as unverified.

The archive report establishes that activity settings, recording, sleep/nap saving surfaces and
activity-type service routes exist. It contains alternative ten- and fifteen-minute exertion captions.
Those resource strings do not establish the active threshold, a complete sport classifier, its model
weights or an offline implementation. DSTA's own UI explicitly says its HR-only detection does not
infer the activity type. Its live detector needs a connected band; transplanting it would not provide
reliable automatic running-versus-dancing classification or background execution guarantees.

## Existing Woop coverage

The canonical workout catalogue already contains 101 selectable activities, including Running,
Treadmill run, Dancing, Ballet, Breakdancing, Strength, swimming and cycling. The same catalogue feeds
both Start Activity and manual add/edit. Sleep remains a separate sleep-analysis flow rather than a
workout preset. Apple Health has its own workout activity mapping, including dance.

Woop's existing movement/heart-rate candidate engine, confirmation state, source-aware deduplication
and selected-day timeline remain the integration path. Detection is opt-in, suggestions require
confirmation, and health data availability determines coverage. Merely supporting a named activity
must never be presented as automatically recognising it.

## Changes from this audit

Search now finds canonical activities from everyday terms such as Dance, Gym, Breakdance and Indoor
running without changing stored labels. Dancing is also available in the detected-workout quick-relabel
menu; the full manual editor retains all catalogue activities. Regression coverage checks discovery,
empty/no-result queries and unchanged canonical lookup behavior. No executable code, proprietary
assets, model weights or unvalidated motion decoder were copied from the WHOOP archive.

Remaining work: validated multi-sport recognition, an explicit user-controlled automatic-save policy,
and physical-device checks for background capture/import and same-day presentation. These are not
completed by catalogue/search support and are not advertised as implemented.
