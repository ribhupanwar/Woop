# Automatic gym recognition: implementation findings

Reviewed 2026-11-09. Analysis migration required: no. Research only; no classifier or sensor capture
has shipped in this change. Existing calorie edits are presentation-only.

## Findings and sources

1. Garmin supports rep counting, exercise recognition and optional automatic set detection in its
   strength profile. Its documentation limits a set to one movement and notes that the count can appear
   only after several reps. This is wrist-motion inference, not universal exercise/weight measurement.
   https://support.garmin.com/en-US/?faq=xEPSpxE3j27gpEsiq8K9o8
   https://www8.garmin.com/manuals/webhelp/GUID-025D75CF-3445-49E1-8D81-1AA74AB4E00F/EN-US/GUID-573EC4B6-D45B-46E7-BE37-FB542CBB4FC1.html
2. Apple documents training an activity classifier from Apple Watch accelerometer/gyroscope data.
   Core Motion supplies inputs; it does not supply a ready-made gym exercise/rep model. A trained
   classifier and a separate repetition/segmentation method must be developed and evaluated.
   https://developer.apple.com/documentation/createml/mlactivityclassifier
   https://developer.apple.com/videos/play/wwdc2019/426/
3. aparande/workout-tracker is a concrete Watch prototype: the wearer calibrates five repetitions
   before counting that chosen exercise. It is a useful feasibility reference for personalized counting,
   not evidence of arbitrary exercise recognition. GitHub reports no declared licence; no code copied.
   https://github.com/aparande/workout-tracker
4. Microsoft RecoFit separates exercise/rest segmentation, exercise classification and repetition
   counting. Its published research reports strong results in its evaluation circuits; those results
   do not establish Woop accuracy. Its data uses forearm sensor recordings, not a verified Apple Watch
   Ultra 1 model. The dataset repository has nonstandard licensing; inspect actual terms before use.
   https://www.microsoft.com/en-us/research/publication/recofit-using-wearable-sensor-find-recognize-count-repetitive-exercises/
   https://github.com/microsoft/Exercise-Recognition-from-Wearable-Sensors
5. MM-Fit provides synchronized exercise sessions and wearable recordings, with example model code.
   Code and dataset terms must be checked separately. Other sensor locations, multiple sensors and
   camera-assisted results cannot be treated as wrist-only performance. No model/data copied.
   https://mmfit.github.io/
   https://github.com/KDMStromback/mm-fit

## Best fit for this owner's devices

Start with the installed Woop Apple Watch companion during an explicitly started strength session.
Keep the chosen routine/exercise as context, collect bounded accelerometer/gyro samples and calibrate
supported movements. A candidate counter should propose reps for that exercise, with manual correction
and confirmation before writing a performed set. Do not prefill performed reps from the plan.

Start evaluation with distinct wrist-moving exercises and negatives: curls, presses and rows; rest,
walking, adjusting equipment, incomplete reps and transitions. Test different cadence, load, grip,
wrist orientation, fatigue and both wrists. Include stationary-wrist leg movements to establish where
counting must abstain. Report per-exercise count error, missed/extra reps, false sets during rest,
latency, battery impact and generalization to a session excluded from calibration.

Only after validated counting should exercise recognition and automatic set boundaries be enabled.
Keep raw captures local, optional, bounded and deletable. Do not run high-rate motion capture all day.
A Watch app installation is required; the iPhone IPA alone cannot read continuous wrist motion.
WHOOP HR alone cannot resolve repetitions or load. WHOOP MG motion decoding is not currently a
validated rep stream; its presence is not evidence of supported recognition. Weight remains entered
or confirmed by the wearer: wrist motion does not uniquely identify the load.

## Current boundary

Woop already has routine context, native set logging, correction/history and Watch physiological
recording. It has no Watch motion rep-capture pipeline, calibrated counter, trained exercise model or
hardware evaluation for these features. This document is a concrete development route, not a claim
that Garmin-style recognition is implemented. No camera permission or third-party service was added.
