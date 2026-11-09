# VO2 max article review

Analysis migration required: no. This review does not change a scoring formula, source precedence or stored value.

Source: [the5krunner, WHOOP GPS-free VO2 max patent overview](https://the5krunner.com/2026/11/03/quick-read-whoop-vo2-max-patent/),
read 2026-11-07. The article reports a sleep-heart-rate/profile/training-zone baseline, GPS-run refinement,
a lookback example of 90 days, and dated laboratory-result calibration. It also describes optional daily
updates and calibration decay. These are article-reported patent concepts, not independently verified
production behavior or an implemented equation.

The page does not supply a reproducible baseline formula, complete coefficients, trained model weights,
training cohort, error distribution or a validation dataset. The linked publication identifier could not
be retrieved from the primary patent service during this review. No coefficients are inferred or invented.
A lab-minus-estimate offset is only meaningful once the underlying estimator has itself been validated;
adding that offset to an arbitrary baseline would not reproduce WHOOP's method.

## Woop's current boundary

- `HealthspanVO2` already prefers dated wearer-entered lab values, then Apple Health Cardio Fitness
  readings. Neither is a direct oxygen measurement by the phone or WHOOP band.
- The separate running/walking `ExerciseVO2max` instrument is experimental. Its documented lab comparison
  failed the criterion for promotion into Healthspan; this article does not override that evidence.
- The non-exercise estimate also remains separate from measured-source Healthspan inputs.

Preserve source labels and missing-data states. A future GPS-free estimator needs an independently
specified model, reliable sleep HR and training/profile inputs, validation against measured VO2 max over
a range of athletes, and a dated calibration policy. A patent overview alone does not satisfy those gates.

## Additional primary-source comparison

[Apple's Cardio Fitness technical paper](https://www.apple.com/healthcare/docs/site/Using_Apple_Watch_to_Estimate_Cardio_Fitness_with_VO2_max.pdf)
was retrieved and inspected. It describes a submaximal estimate from HR response during outdoor
walking/running/hiking with adequate GPS/HR quality. Its May 2021 validation results are not a guarantee
for an individual Ultra 1 user or the current watchOS algorithm. The paper itself reports residual error;
Apple Watch VO2 max must be labelled a vendor estimate, not a laboratory oxygen measurement. A good
route/HR trace and correct Health profile inputs matter more than forcing a WHOOP-matching value.

The existing Healthspan engine explicitly models an effective age from published risk relationships,
with assumptions for overlapping inputs. It is not a measured biological age or life expectancy. Neither
that model nor the article justifies a promise of 100% accuracy or identical WHOOP results. For this owner,
retain dated lab results/Watch estimates with provenance, preserve trends and show insufficient data
rather than promote the unvalidated exercise estimator.
