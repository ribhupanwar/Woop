# Health, pull sync and automatic training review

Analysis migration required: no.

This change is based on `feature/whoop-575-ui-parity` at `90297f3`. References are the user's Health Monitor screenshot and the metadata-only findings in [ribhupanwar/dsta](https://github.com/ribhupanwar/dsta/blob/main/docs/WHOOP-archive-findings.md). No proprietary implementation, font, artwork or model is included.

## Implemented

- The Health hero keeps a large BPM readout beside a blue rolling time chart, with a latest-sample rule and dot and touch inspection. Zone numbers come from the existing profile resolver, including zone 0. The chart no longer invents timestamps for R-R packets or creates a flat pre-observation history. Connection loss or a sampling gap clears the trace.
- Every Home style requests the existing gated strap history sync and then refreshes local data. The WOOP wordmark and the existing original Forge glyph appear during a pull. Reduced Motion keeps the glyph static. Offline pulls still reload local data.
- The pull waits up to 20 seconds for history, with a two-second quiet tail to cover chunk boundaries. A longer transfer remains visible in the existing sync status; finishing the pull is not reported as successful strap sync. Actual outcomes retain the existing last-sync and error state.
- Training retains its native OpenGym-style routines, progression, rest timers and running quick start. An accessible activity-detection switch and the existing shared suggestion prompt are now available there. Detection proposes sessions after sync and requires confirmation; it does not identify every gym movement or count reps.
- The IPA workflow accepts PRs targeting the active UI branch and checks out the triggering SHA. Previously the workflow always built a fixed branch, which would not validate a PR's changes.

## Model selection

For iPhone camera-assisted repetition counting, the recommended starting point is Apple's native [Create ML Components action-repetition counter](https://developer.apple.com/documentation/createmlcomponents/counting-human-body-action-repetitions-in-a-live-video-feed). It operates on a pose stream from live video. It is not wrist-only tracking or a universal exercise recognizer. Camera placement, exercise-specific evaluation, permission copy and a confirmation step are required before shipping a set count. This review does not enable camera capture or install a model.

[MediaPipe Pose Landmarker](https://developers.google.com/edge/mediapipe/solutions/vision/pose_landmarker) is a cross-platform alternative supplying 33 body landmarks. Rep counting and exercise recognition still need application logic and evaluation; it is not a drop-in WHOOP motion model.

For wrist-only counting, [Microsoft RecoFit](https://github.com/microsoft/Exercise-Recognition-from-Wearable-Sensors) supplies accelerometer/gyroscope research recordings from over 200 participants. It is a dataset, not a production Core ML model validated on WHOOP 5. Wrist placement, units, sampling rate, exercise coverage and subject-separated evaluation must match the target device. Dsta explicitly marks the proposed WHOOP 5 raw-IMU command/decoder layout as unverified. Feeding it to a generic pretrained model would not establish correct exercise names or repetition counts. No unverified raw-data commands are added.

For running, the existing phone GPS distance, pace, route recording, heart-rate zones and workout history are sufficient for the current scope. A camera rep model does not improve those measurements. New running features should follow observed gaps in actual runs, rather than adding a second activity classifier.

## Verification

- `git diff --check` and `Tools/doc_comment_lint.py` pass.
- All added UI strings have translations in the nine existing non-English catalog locales. The full i18n gate still reports 14 missing catalog entries already present on the base UI branch; none are introduced by this change.
- Apple compilation and UI/device verification require macOS/Xcode and a connected strap. No on-device validation or exact pixel-match claim is made here. The PR workflow validates the triggering revision rather than an unrelated fixed branch.
