import Foundation
import WebKit
import RegexBuilder

/// View model for campaign detail web view.
///
final class BlazeCampaignDetailWebViewModel: AuthenticatedWebViewModel {
    let title = "" // the title is set on the SwiftUI view
    let initialURL: URL?

    private let siteURL: String
    private let onDismiss: () -> Void
    private let onCampaignCreation: (Int64) -> Void

    init(initialURL: URL,
         siteURL: String,
         onDismiss: @escaping () -> Void,
         onCampaignCreation: @escaping (Int64) -> Void) {
        self.initialURL = initialURL
        self.siteURL = siteURL
        self.onDismiss = onDismiss
        self.onCampaignCreation = onCampaignCreation
    }

    func handleDismissal() {
        // no-op
    }

    func handleRedirect(for url: URL?) {
        guard let url, let initialURL else {
            return
        }

        if let productID = retrieveProductIDForCampaignCreation(from: url, baseURL: initialURL) {
            onCampaignCreation(productID)
        } else if checkCampaignListURL(for: url, siteURL: siteURL) {
            onDismiss()
        }
    }

    func decidePolicy(for navigationURL: URL) async -> WKNavigationActionPolicy {
        .allow
    }
}

private extension BlazeCampaignDetailWebViewModel {
    /// Returns true if the current URL triggers the dismissal of the campaign detail screen.
    ///
    func checkCampaignListURL(for url: URL, siteURL: String) -> Bool {
        let expectedURL = String(format: Constants.campaignListURLFormat,
                                 siteURL.trimHTTPScheme())
        return url.absoluteString == expectedURL
    }

    /// Returns the product ID if the current URL is detected as a trigger
    /// given the provided `baseURL`.
    ///
    func retrieveProductIDForCampaignCreation(from url: URL, baseURL: URL) -> Int64? {
        guard url.absoluteString.hasPrefix(baseURL.absoluteString) else {
            return nil
        }

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let item = components?.queryItems?.first(where: { $0.name == Constants.campaignCreationParam })
        guard let item else {
            return nil
        }

        let productID = Reference(Int64.self)
        let regex = Regex {
            "post-"
            TryCapture(as: productID) {
                OneOrMore(.digit)
            } transform: { match in
                Int64(match)
            }
        }

        if let result = item.value?.firstMatch(of: regex) {
            return result[productID]
        }
        return nil
    }
}

private extension BlazeCampaignDetailWebViewModel {
    enum Constants {
        static let campaignCreationParam = "blazepress-widget"
        static let campaignListURLFormat = "https://wordpress.com/advertising/campaigns/%@"
    }
}
