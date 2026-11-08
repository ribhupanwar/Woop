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
