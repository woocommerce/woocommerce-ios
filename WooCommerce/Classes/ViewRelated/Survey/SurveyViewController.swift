import UIKit
import WebKit
import class Networking.UserAgent

/// Outputs of the the SurveyViewController
///
protocol SurveyViewControllerOutputs: UIViewController {
    /// Handler invoked when the survey has been completed
    ///
    var onCompletion: () -> Void { get }
}

/// Shows a web-based survey
///
final class SurveyViewController: UIViewController, SurveyViewControllerOutputs {

    /// Internal web view to render the survey
    ///
    @IBOutlet private weak var webView: WKWebView!

    /// Survey configuration provided by the consumer
    ///
    private let survey: Source

    /// Handler invoked when the survey has been completed
    ///
    let onCompletion: () -> Void

    /// Loading view displayed while the survey loads
    ///
    private let loadingView = LoadingView(waitMessage: Localization.wait)

    init(survey: Source, onCompletion: @escaping () -> Void) {
        self.survey = survey
        self.onCompletion = onCompletion
        super.init(nibName: Self.nibName, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        addCloseNavigationBarButton()
        loadingView.showLoader(in: view)
        configureAndLoadSurvey()
    }

    private func configureAndLoadSurvey() {
        title = survey.title

        let request = URLRequest(url: survey.url)
        webView.customUserAgent = UserAgent.defaultUserAgent
        webView.load(request)
        webView.navigationDelegate = self
    }
}

// MARK: Survey Configuration
//
extension SurveyViewController {
    enum Source {
        case inAppFeedback
        case productsFeedback
        case addOnsI1
        case orderCreation
        case orderFormShippingLines
        case aiAssistantFeedback

        fileprivate var url: URL {
            let url: URL = {
                switch self {
                case .inAppFeedback:
                    return WooConstants.URLs.inAppFeedback
                        .asURL()
                case .productsFeedback:
                    return WooConstants.URLs.productsFeedback
                        .asURL()
                case .addOnsI1:
                    return WooConstants.URLs.orderAddOnI1Feedback
                        .asURL()
                case .orderCreation:
                    return WooConstants.URLs.orderCreationFeedback
                        .asURL()
                case .orderFormShippingLines:
                    return WooConstants.URLs.orderCreationShippingFeedback
                        .asURL()
                case .aiAssistantFeedback:
                    return WooConstants.URLs.aiAssistantFeedback
                        .asURL()
                }
            }()

            let session = ServiceLocator.stores.sessionManager
            return url
                .tagPlatform("ios")
                .tagAppVersion(Bundle.main.bundleVersion())
                .tagSiteInfo(siteID: session.defaultSite?.siteID,
                             storeUUID: session.defaultStoreUUID,
                             storeURL: session.defaultSite?.url)
        }

        fileprivate var title: String {
            switch self {
            case .inAppFeedback:
                return Localization.title
            case .productsFeedback,
                    .addOnsI1,
                    .orderCreation,
                    .orderFormShippingLines,
                    .aiAssistantFeedback:
                return Localization.giveFeedback
            }
        }

        /// The corresponding `FeedbackContext` for event tracking purposes.
        var feedbackContextForEvents: WooAnalyticsEvent.FeedbackContext {
            switch self {
            case .inAppFeedback:
                return .general
            case .productsFeedback:
                return .productsGeneral
            case .addOnsI1:
                return .addOnsI1
            case .orderCreation:
                return .orderCreation
            case .orderFormShippingLines:
                return .orderFormShippingLines
            case .aiAssistantFeedback:
                return .aiAssistant
            }
        }
    }
}

// MARK: WebView Delegate
//
extension SurveyViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        defer {
            decisionHandler(.allow)
        }

        // To consider the survey as completed, the following conditions need to occur:
        // - Survey Form is submitted.
        // - The request URL contains a `msg` parameter key with `done` as it's value
        //
        guard case .formSubmitted = navigationAction.navigationType,
            let url = navigationAction.request.url,
            let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
            let surveyMessageValue = queryItems.first(where: { $0.name == Constants.surveyMessageParameterKey })?.value else {
                return
        }

        if surveyMessageValue == Constants.surveyCompletionParameterValue {
            onCompletion()
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation) {
        loadingView.hideLoader()
    }
}
// MARK: Survey Tags
//
extension URL {
    func tagPlatform(_ platformName: String) -> URL {
        appendingQueryItem(URLQueryItem(name: Tags.surveyRequestPlatformTag, value: platformName))
    }

    func tagAppVersion(_ version: String) -> URL {
        appendingQueryItem(URLQueryItem(name: Tags.surveyRequestAppVersionTag, value: version))
    }

    func tagSiteInfo(siteID: Int64?,
                     storeUUID: String?,
                     storeURL: String?) -> URL {
        var url = self
        if let siteID {
            url = url.appendingQueryItem(URLQueryItem(name: Tags.surveyRequestSiteIdTag, value: "\(siteID)"))
        }
        if let storeUUID {
            url = url.appendingQueryItem(URLQueryItem(name: Tags.surveyRequestStoreUUIDTag, value: storeUUID))
        }
        if let storeURL {
            url = url.appendingQueryItem(URLQueryItem(name: Tags.surveyRequestStoreURLTag, value: storeURL))
        }
        return url
    }

    private func appendingQueryItem(_ queryItem: URLQueryItem) -> URL {
        guard var urlComponents = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            assertionFailure("Cannot create URL components from \(self)")
            return self
        }
        let queryItems: [URLQueryItem] = urlComponents.queryItems ?? []
        urlComponents.queryItems = queryItems + [queryItem]
        guard let url = try? urlComponents.asURL() else {
            assertionFailure("Cannot convert URL components to URL: \(urlComponents)")
            return self
        }
        return url
    }

    private enum Tags {
        static let surveyRequestPlatformTag = "woo-mobile-platform"
        static let surveyRequestAppVersionTag = "app-version"
        static let surveyRequestSiteIdTag = "site-id"
        static let surveyRequestStoreUUIDTag = "store-id"
        static let surveyRequestStoreURLTag = "store-url"
    }
}

// MARK: Constants
//
private extension SurveyViewController {
    enum Constants {
        static let surveyMessageParameterKey = "msg"
        static let surveyCompletionParameterValue = "done"
    }

    enum Localization {
        static let wait = NSLocalizedString("Please wait", comment: "Text on the loading view of the survey screen indicating the user to wait")
        static let title = NSLocalizedString("How can we improve?", comment: "Title on the navigation bar for the in-app feedback survey")
        static let giveFeedback = NSLocalizedString("Give feedback", comment: "Title on the navigation bar for the products feedback survey")
    }
}
