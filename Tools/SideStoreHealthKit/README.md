# Personal SideStore HealthKit test build

This harness builds official SideStore nightly 1503 with the existing human-authored
[SideSign HealthKit patch](https://github.com/SideStore/SideSign/pull/3). It is a personal test build,
not an official SideStore release or an upstream contribution. No issue, PR or maintainer message is
created in either upstream repository.

Pinned source:

- SideStore: `12ff39c6b6c0ccd8180f0834a893a4bbaf7bcd31`
- SideSign: `752d1ef602aa792a432ffa1e71646dc1ecf7363c`
- Human-authored patch commit: `74950d37f2333d29cbf3bfc9ca4a60820498c2d3`
- Downloaded patch SHA-256: `e5fcb6e7d04e388e61635f4d825450209407226072a998a3a9fd37f20d5927eb`

The change maps the HealthKit entitlement to its App-ID capability and adds it to the free-account
allowlist. Authentication, Anisette configuration, pairing, certificates and network endpoints are
unchanged from the official base. The build uses no user's Apple credentials or device identifiers.

The workflow first proves the original two signing models fail the basic HealthKit check, then applies
the hash-verified patch and requires the same check to pass. It archives and packages using the
upstream Makefile. Artifact provenance and the applied diff accompany the IPA. This does not verify
phone installation, Apple sign-in, free-account provisioning, or Health permissions on iOS 27.

## Device handoff after a successful build

1. Keep a backup of Woop's recorded data before testing installer changes. The current SideStore
   installation should not be removed as an initial troubleshooting step.
2. The official [SideStore FAQ](https://docs.sidestore.io/docs/faq) permits installing a test/nightly IPA
   through existing SideStore or iloader, while noting data preservation is not guaranteed for test
   builds. Use the same Apple Account for the in-place installation; sign in locally, never in chat.
3. With the patched installer running, sign the Woop Lite IPA that contains the HealthKit capability
   request. Woop's packaging fix is separate from the installer fix; both are needed on this route.
4. In Woop, open Apple Health and request access. Grant the desired types on the phone. Verify an
   actual permitted measurement imports with the correct source/date; a visible permission sheet
   alone is not proof that all Health data is available.
5. If signing/provisioning fails, record the exact error. Do not delete App IDs, revoke certificates or
   remove the existing app as an automatic repair; those actions can affect installed apps and data.

Windows is sufficient for the user-side installation workflow; Xcode runs on GitHub's macOS runner.
The current Woop Lite IPA still has no Watch companion, so this does not provide live Watch streaming.
