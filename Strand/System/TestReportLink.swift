import Foundation
import StrandAnalytics

/// Builds the prefilled GitHub new-issue URL for a Test Centre report (spec section 5.2). It binds
/// the bug form's existing id fields (version, platform, os_version, test_profile, title) and
/// self-applies the "bug,test:<id>" labels so a submission lands pre-labelled on the right cluster.
/// Every query value is percent-encoded by URLComponents. No network, no cloud: this only composes a
/// URL the caller opens in the browser. Repo is NoopApp/noop (confirmed in bug_report.yml).
enum TestReportLink {

    /// The prefilled new-issue URL, or nil if URLComponents cannot form it. `profile.id` is the wire
    /// id (dataImport -> "import"); `profile.githubLabel` is "test:<id>" (master -> "test:all").
    static func reportURL(profile: TestDomain, title: String,
                          version: String, platform: String, osVersion: String) -> URL? {
        var c = URLComponents(string: "https://github.com/NoopApp/noop/issues/new")
        c?.queryItems = [
            .init(name: "template", value: "bug_report.yml"),
            .init(name: "labels", value: "bug,\(profile.githubLabel)"),
            .init(name: "version", value: version),
            .init(name: "platform", value: platform),
            .init(name: "os_version", value: osVersion),
            .init(name: "test_profile", value: profile.id),
            .init(name: "title", value: "[\(profile.id)] \(title)"),
        ]
        return c?.url
    }
}
