import Foundation

// Compile directly with the two upstream model files; no Apple ID, network session or signing key.
let entitlement = Entitlement(rawValue: "com.apple.developer.healthkit")
guard entitlement.isFreeAllowed,
      let feature = Feature(entitlement: entitlement),
      feature.rawValue == "HK421J6T7P",
      Feature.freeFeatures.contains(feature),
      Feature.paidFeatures.contains(feature) else {
    fputs("HealthKit is not provisionable through this signing-model path\n", stderr)
    exit(1)
}
// Basic HealthKit support must not imply clinical health-record access.
guard !Entitlement.healthKitAccess.isFreeAllowed else {
    fputs("Unexpected expansion of clinical health-record entitlement\n", stderr)
    exit(1)
}
print("PASS: basic HealthKit maps to the App-ID feature and survives the free-account allowlist")
