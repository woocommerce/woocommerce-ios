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
        case productsM5Feedback
        case shippingLabelsRelease1Feedback

        fileprivate var url: URL {
            switch self {
            case .inAppFeedback:
                return WooConstants.URLs.inAppFeedback
                    .asURL()
                    .tagPlatform("ios")
                    .tagAppVersion(Bundle.main.bundleVersion())

            case .productsM5Feedback:
                return WooConstants.URLs.productsM4Feedback
                    .asURL()
                    .tagPlatform("ios")
                    .tagProductMilestone("5")
                    .tagAppVersion(Bundle.main.bundleVersion())
            case .shippingLabelsRelease1Feedback:
                return WooConstants.URLs.shippingLabelsRelease1Feedback
                    .asURL()
                    .tagPlatform("ios")
                    .tagShippingLabelsMilestone("1")
                    .tagAppVersion(Bundle.main.bundleVersion())
            }
        }

        fileprivate var title: String {
            switch self {
            case .inAppFeedback:
                return Localization.title
            case .productsM5Feedback, .shippingLabelsRelease1Feedback:
                return Localization.giveFeedback
            }
        }

        /// The corresponding `FeedbackContext` for event tracking purposes.
        var feedbackContextForEvents: WooAnalyticsEvent.FeedbackContext {
            switch self {
            case .inAppFeedback:
                return .general
            case .productsM5Feedback:
                return .productsM4
            case .shippingLabelsRelease1Feedback:
                return .shippingLabelsRelease1
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

    func tagProductMilestone(_ milestone: String) -> URL {
        appendingQueryItem(URLQueryItem(name: Tags.surveyRequestProductMilestoneTag, value: milestone))
    }

    func tagShippingLabelsMilestone(_ milestone: String) -> URL {
        appendingQueryItem(URLQueryItem(name: Tags.surveyRequestShippingLabelsMilestoneTag, value: milestone))
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
        static let surveyRequestProductMilestoneTag = "product-milestone"
        static let surveyRequestShippingLabelsMilestoneTag = "shipping_label_milestone"
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
