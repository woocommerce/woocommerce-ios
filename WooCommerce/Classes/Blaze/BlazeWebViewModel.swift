import Foundation
import WebKit
import struct Yosemite.Site

/// Blaze entry points.
enum BlazeSource {
    /// From the Blaze campaign list
    case campaignList
    /// From the Blaze intro view
    case introView
    /// From the Create campaign button on the Blaze section of the My Store screen
    case myStoreSection
    /// From the "Promote with Blaze" button on product form
    case productDetailPromoteButton
}

/// View model for Blaze webview.
final class BlazeWebViewModel {
    let title = "Blaze"
    let initialURL: URL?

    // MARK: - Analytics
    private let baseURLString: String
    private var currentStep = WooAnalyticsEvent.Blaze.Step.unspecified
    private var hasTrackedStartEvent: Bool = false
    private var isCompleted: Bool = false

    private let source: BlazeSource
    private let siteID: Int64
    private let siteURL: String
    private let productID: Int64?
    private let userDefaults: UserDefaults
    private let onCampaignCreated: (() -> Void)?

    init(siteID: Int64,
         source: BlazeSource,
         siteURL: String,
         productID: Int64?,
         userDefaults: UserDefaults = .standard,
         onCampaignCreated: (() -> Void)? = nil) {
        self.siteID = siteID
        self.source = source
        self.siteURL = siteURL
        self.productID = productID
        self.userDefaults = userDefaults
        self.onCampaignCreated = onCampaignCreated
        self.initialURL = {
            let url = siteURL.trimHTTPScheme()
            let urlString: String = {
                if let productID {
                    return String(format: Constants.blazePostURLFormat, url, productID, source.analyticsValue)
                } else {
                    return String(format: Constants.blazeSiteURLFormat, url, source.analyticsValue)
                }
            }()
            return URL(string: urlString)
        }()
        self.baseURLString = {
            let siteURL = siteURL.trimHTTPScheme()
            return String(format: Constants.baseURLFormat, siteURL)
        }()
    }
}

extension BlazeWebViewModel: AuthenticatedWebViewModel {
    func decidePolicy(for navigationURL: URL) async -> WKNavigationActionPolicy {
        .allow
    }

    func handleDismissal() {
        if !isCompleted {
            ServiceLocator.analytics.track(event: .Blaze.blazeFlowCanceled(source: source, step: currentStep))
        }
    }

    func handleRedirect(for url: URL?) {
        guard let url else {
            return
        }
        if !hasTrackedStartEvent {
            ServiceLocator.analytics.track(event: .Blaze.blazeFlowStarted(source: source))
            hasTrackedStartEvent = true
        }

        currentStep = extractCurrentStep(from: url) ?? currentStep
        if currentStep == Constants.completionStep && !isCompleted {
            ServiceLocator.analytics.track(event: .Blaze.blazeFlowCompleted(source: source, step: currentStep))
            isCompleted = true
            // TODO: make Blaze card appear on the dashboard again
            onCampaignCreated?()
        }
    }

    func didFailProvisionalNavigation(with error: Error) {
        ServiceLocator.analytics.track(event: .Blaze.blazeFlowError(source: source, step: currentStep, error: error))
    }
}

private extension BlazeWebViewModel {
    /// Based on JPiOS implementation:
    /// https://github.com/wordpress-mobile/WordPress-iOS/blob/01df04e28f5eeca28d28935c2999c9a12f32f372/WordPress/Classes/ViewRelated/Blaze/Webview/
    /// BlazeWebViewModel.swift#L117
    /// - Parameter request: URL request from the webview.
    /// - Returns: Optional step of the Blaze flow.
    func extractCurrentStep(from url: URL) -> WooAnalyticsEvent.Blaze.Step? {
        guard url.absoluteString.hasPrefix(baseURLString) else {
            return nil
        }
        if let query = url.query, query.contains(Constants.blazeWidgetQueryIdentifier) {
            if let step = url.fragment {
                return .custom(step: step)
            }
            else {
                return .step1
            }
        } else {
            if let lastPathComponent = url.pathComponents.last, lastPathComponent == Constants.blazeCampaignsURLPath {
                return .campaignList
            } else {
                return .productList
            }
        }
    }
}

private extension BlazeWebViewModel {
    enum Constants {
        static let blazeSiteURLFormat = "https://wordpress.com/advertising/%@?source=%@"
        static let blazePostURLFormat = "https://wordpress.com/advertising/%@?blazepress-widget=post-%d&source=%@"

        // MARK: - Analytics
        static let baseURLFormat = "https://wordpress.com/advertising/%@"
        static let blazeWidgetQueryIdentifier = "blazepress-widget"
        static let blazeCampaignsURLPath = "campaigns"
        // Deducted from JPiOS Tracks event `jpios_blaze_flow_completed`.
        static let completionStep: WooAnalyticsEvent.Blaze.Step = .custom(step: "step-5")
    }
}
