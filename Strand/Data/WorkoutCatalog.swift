import Foundation
import StrandCore

// The localized side of `WorkoutCatalog` (StrandCore): sport names in the wearer's language and the search
// over them. Kept in the app so the string catalogue keeps extracting them.
extension WorkoutCatalog.Sport {
    /// The name in the wearer's language. `name` stays the stored, locale-stable key.
    var displayName: String { WorkoutSource.localizedDisplaySport(name) }
}

extension WorkoutCatalog {
    /// Search-only synonyms preserve canonical stored sport labels and never classify sensor data.
    private static let searchAliases: [String: [String]] = [
        "Dancing": ["dance", "social dance"],
        "Breakdancing": ["breakdance", "breaking"],
        "Strength": ["gym", "workout", "strength training", "weight training"],
        "Treadmill run": ["indoor running", "indoor run"],
        "Indoor cycle": ["indoor cycling", "stationary bike"],
        "Pool swim": ["pool swimming", "indoor swimming"],
        "Open-water swim": ["open water swimming", "outdoor swimming"],
        "Martial arts": ["mixed martial arts", "mma"]
    ]

    /// Catalogue filtered by translated names, canonical names and search-only synonyms.
    static func matching(_ query: String) -> [Sport] {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return all }
        // Matches the stored English key and the translated name, so "Laufen" finds Running.
        return all.filter {
            $0.name.range(of: q, options: .caseInsensitive) != nil
                || $0.displayName.range(of: q, options: [.caseInsensitive, .diacriticInsensitive]) != nil
                || (searchAliases[$0.name] ?? []).contains {
                    $0.range(of: q, options: [.caseInsensitive, .diacriticInsensitive]) != nil
                }
        }
    }
}
