# Woop Android preview APK

Analysis migration required: no.

The Android APK workflow builds the existing fullDebug Kotlin app, with demo data disabled, for Android
8.0 or later. It is signed with a testing key and installs as io.github.dx23876.noop.debug. It is a preview,
not a production signing/release commitment. Preserve/export data before replacing an APK signed by a
different key; this workflow does not uninstall an existing app or alter its identity.

The optional Swift JNI core is explicitly omitted with the existing noop.swiftCore=false build option.
The repository documents this fallback as the existing Kotlin app. Latest Swift-only automatic saving,
iPhone layout, sleep planner and Health navigation changes are not automatically ported to Android.
BLE, background permissions, recording and GPS need validation on a physical Android phone and band.

The artifact contains the installable APK, SHA-256 checksum and source/variant provenance. Android JVM
tests run in the same workflow; an uploaded diagnostic candidate does not imply a passing test suite.

The owner clarified that the APK must use the Woop layout and shared features. The build now requires the
Swift 6.4.1 Android SDK/NDK r30 and bundles the shared arm64 core; the Kotlin-only preview described above
is superseded and is not the requested deliverable. The SDK setup action also names platform-tools
explicitly, because its default obsolete tools package failed on the current Android repository.
The Android presentation port remains incremental; successful packaging alone does not establish parity.
Analysis migration required: no.

## Android presentation port

The initial port pins the reference Home, with Sleep/Recovery/Strain ring order, dark canvas, own wordmark,
monitor navigation, selected-day ascending sleep/workout rows, Add/Start Activity entries, Tonight's Sleep
and a debt-based planner. The tab bar is Home / Health / Activity / More; Health links existing age, vital,
stress, measured-BP logbook and MG ECG surfaces, preserving their existing data/consent gates. Existing
workout recording/editor flows remain reachable. Metric rows use independent full-width reference cards.
The planner reads raw values already supplied by the shared sleep-debt API and uses the iPhone's bounded
repayment heuristic; tests cover invalid inputs and bounds. It does not promise sleep consistency.

This full-core APK targets Android 9+ arm64, matching the native library's Android 28 target. Packaging
checks the native library and APK signature. The preview signing key is cached for consistent subsequent
CI builds; it is not production signing. A local Swift test attempt failed because Swift is absent here;
Android compilation and JVM tests run on CI. Pixel comparison, actual BLE/GPS and background permissions,
Health Connect, complete automatic-save settings/provenance UI, reference charts and all secondary-screen
parity remain unverified or incomplete. No Android release is certified by the iPhone workflow.
Analysis migration required: no.

## Automatic save host wiring

Android passes its detection switch, separate automatic-save opt-in, activation timestamp, walking
choice and sensitivity through the existing analysis extras to the shared host. The same ActivitySuggestions
eligibility, settlement, activation and deduplication rules run after analysis. Re-enabling detection with
automatic saving active resets the capture window; enabling automatic saving also resets it. Defaults
remain off. Core-only automatic rows strip the provenance prefix when resolving the actual storage owner
for edits/dismissal. Timeline/sleep reads observe committed core revisions, avoiding stale rows until a
workout-count change. Tests cover default-off extras and automatic source-to-owner mapping. Settings take
effect on the next analysis configuration; in-flight host settings/device behavior require validation.
No physiological formula or historical input changes. Analysis migration required: no.

Android Home now includes real intraday stress and seven-day strain/recovery charts. They read committed
core data off the main thread, redraw without animation, and break at missing samples/days. Normalized
stored strain is presented on a 0-21 axis. The equivalent iPhone chart was corrected to apply its existing
strain display conversion rather than dropping stored 0-100 readings above 21. No scores are rewritten.
The iPhone validation workflow now retains its macOS xcresult and a summary even when quiet xcodebuild
fails without a useful console failure; the 18678fd validation failure remains under diagnosis.
Analysis migration required: no.

Gradle's official distribution redirect returned HTTP 504 after the wrapper timeout repair. CI now
bootstraps Gradle 8.7 with retry and an alternate mirror only when official download fails; both paths
must match the repository's existing pinned SHA-256. Dependency verification/lockfiles remain enabled.
