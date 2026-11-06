# Rusheel Raj WHOOP 5.0 reverse-engineering cross-audit

Date: 2026-11-06
Repository: `ribhupanwar/Woop`
Branch audited: `fix/unified-today-auto-gps-sleep`

## Executive result

The ZHOOP article is useful corroborating evidence, but it does not reveal a missing protocol implementation that should be copied wholesale into Woop. Woop already contains a more extensive WHOOP 5.0/MG protocol implementation, real-capture fixtures, integrity checks, persistent raw-signal stores, and cross-platform parity tests. Several article details are either simplified or conflict with Woop's larger captured corpus.

No runtime algorithm or protocol offsets were changed as a result of this audit. Do not overwrite the current decoder with the article's snippets.

## Cross-check

| Topic | ZHOOP article | Woop branch | Decision |
|---|---|---|---|
| Puffin framing | AA01, declared length, CRC16/Modbus header, CRC32 inner frame | Family-aware parser and full integrity verdict in `WhoopProtocol` | Already covered; retain |
| Live HR | Type 40, BPM at frame byte 16; history and live HR cannot share the same session | Existing live HR and backfill state machines | Already covered; do not merge streams |
| History ACK | HISTORY_END cursor echoed in opcode 23 after DB flush | `Backfiller.finishChunk` persists decoded rows, rejected archive/raw outbox, then cursor, then confirmed ACK | Existing implementation is stricter; retain |
| v18 HR/RR | HR @22, count @23, RR words @24 onward | Same offsets; Woop converts 1/1024-second ticks to milliseconds and labels source | Woop has additional unit/provenance handling |
| v18 gravity | float32 @45/@49/@53 | Same offsets, real fixtures and gravity validation | Already covered |
| v18 temperature | u16 @73 divided by 128 | Woop stores raw register and uses /100 only after corpus validation (worn median ~34 C; fixture 30.57 C). The article's /128 gives 23.88 C for raw 3057 and conflicts with Woop's validated worn/off-wrist observations. | Do NOT copy /128 |
| v18 movement | gravity plus basic motion inference | Woop additionally decodes dynamic acceleration @41, cumulative motion counter @57, cadence @59, activity class @63, wear quality and sleep band state @81 | Woop has richer fields |
| Raw IMU | Article emphasizes 1 Hz gravity vector | Woop has a dedicated 100 Hz, 6-axis, 100-sample-per-second raw IMU decoder with hardware corpus validation | Prefer Woop high-rate IMU; do not replace with 1 Hz gravity |
| Optical / PPG | Article labels a v26 layout as 24 signed 16-bit samples | Woop has dedicated versioned raw optical layouts, including v20's 5-block/2-channel structure and a separate v26 decoder path; strict CRC and waveform persistence | Version naming/layouts are not interchangeable; validate by frame length, version and checksum |
| Recovery | RMSSD over cleaned RR, resting-window selection, personal baselines | Woop has RR transport reconciliation, suspect-fill filtering, recovery scorer/calibration and sleep-aware signal paths | Reuse concepts only where tests/data show a gap |
| Sleep | Heuristic gravity/HR staging; author explicitly says not EEG | Woop has multiple sleep stagers, fragmented-night handling, confidence/coverage gates and PSG tooling | Do not import the simpler heuristic |
| Steps / activities | 1 Hz gravity step heuristic and HR-elevation activity detection | Woop has cumulative WHOOP5 motion counter, activity-class labels, calibrated step models, and separate walk/HR candidate tracks | Article is not a replacement for the existing pipeline |

## Important protocol distinctions

1. **Do not treat all type-47 versions as the same layout.** Woop's current dispatch recognizes WHOOP 5/MG historical versions 16, 18, 20, 21 and 26. In particular, the article's claimed v26 24-sample structure must not be assumed equivalent to Woop's v20 optical record or any other version without matching a captured frame.
2. **Do not copy the article's temperature divisor.** Woop's parser deliberately preserves the raw register and validates /100 against multiple devices and worn/off-wrist observations. The article's own example raw value 3057 yields 23.88 C under /128, which does not match the Woop fixture's observed 30.57 C worn value.
3. **Do not replace the 100 Hz IMU with 1 Hz gravity.** The dedicated raw IMU decoder uses 100 accelerometer and 100 gyroscope samples per second, and the tests validate the gravity shell and gyro behaviour against real hardware captures.
4. **Do not weaken the history durability invariant.** Woop's Backfiller documents and enforces: decoded insert -> rejected-frame archive -> optional raw capture -> local cursor -> link-confirmed trim ACK. A failed persistence step stalls the ACK so the strap can resend.
5. **Keep proprietary-score claims separate from signal decoding.** ZHOOP itself says its recovery, strain, sleep and biological-age numbers are textbook approximations, not WHOOP's cloud-trained values. Its Uth/HUNT VO2 estimate is not a recovered WHOOP VO2 model.

## Concrete Woop follow-through

- Keep existing v18/v20/v21/v26 decoder and oracle fixtures as source of truth.
- Use the article as independent corroboration for v18 HR/RR/gravity and history ACK ordering, not as a source of replacement offsets.
- When a real Woop capture is available, compare the strap's v18 @63 activity class and @57 counter against the stored minute-level walk/run candidates. This is the most relevant bridge to the reported issue where steps count but an automatic walk/run activity is not surfaced.
- For new raw IMU or PPG work, require a frame fixture, CRC validation, storage round-trip test and downstream consumer test before enabling it in a user-facing score.
- Keep skin temperature as a trend/deviation signal unless absolute calibration is independently established.
- Never send destructive strap commands (trim, reboot, power-cycle, firmware/DFU, fuel-gauge reset).

## Files inspected

- `Packages/WhoopProtocol/Sources/WhoopProtocol/Interpreter.swift`
- `Packages/WhoopProtocol/Sources/WhoopProtocol/HistoricalStreams.swift`
- `Packages/WhoopProtocol/Sources/WhoopProtocol/Whoop5RawImu.swift`
- `Packages/WhoopProtocol/Sources/WhoopProtocol/Whoop5RawOptical.swift`
- `Packages/WhoopProtocol/Tests/WhoopProtocolTests/Whoop5HistoricalTests.swift`
- `Packages/WhoopProtocol/Tests/WhoopProtocolTests/Whoop5RawImuTests.swift`
- `Packages/WhoopProtocol/Tests/WhoopProtocolTests/Whoop5RRTests.swift`
- `Packages/WhoopStore/Sources/WhoopStore/V18Aux.swift`
- `Packages/WhoopStore/Sources/WhoopStore/Whoop5RRReadPolicy.swift`
- `Packages/StrandCore/Sources/StrandCore/Backfiller.swift`
- `Packages/StrandAnalytics/Sources/StrandAnalytics/AutoWorkoutDetector.swift`
- `Packages/StrandAnalytics/Sources/StrandAnalytics/ActivityCandidates.swift`
- `.github/workflows/build-woop-ipa.yml`

## Validation boundary

This was a source and test audit through the repository branch. It did not run Xcode tests, execute a new BLE capture, or produce a new IPA. No claim of build success is made.
