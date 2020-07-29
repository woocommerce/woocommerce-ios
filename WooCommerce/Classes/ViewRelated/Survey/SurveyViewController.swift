import UIKit
import WebKit

/// Shows a web-based survey
///
final class SurveyViewController: UIViewController {

    /// Internal web view to render the survey
    ///
    @IBOutlet private weak var webView: WKWebView!

    /// Survey configuration provided by the consumer
    ///
    private let survey: Source

    /// Handler invoked when the survey has been completed
    ///
    private let onCompletion: () -> Void

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
        configureAndLoadSurvey()
    }

    private func configureAndLoadSurvey() {
        title = survey.title

        let request = URLRequest(url: survey.url)
        webView.load(request)
        webView.navigationDelegate = self
    }
}

// MARK: Survey Configuration
//
extension SurveyViewController {
    enum Source {
        case inAppFeedback

        fileprivate var url: URL {
            switch self {
            case .inAppFeedback:
                return WooConstants.inAppFeedbackURL
            }
        }

        fileprivate var title: String {
            switch self {
            case .inAppFeedback:
                return NSLocalizedString("How can we improve?", comment: "Title on the navigation bar for the in-app feedback survey")
            }
        }
    }
}

// MARK: WebView Delegate
//
extension SurveyViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        // The condition for the POST HTTP method is necessary, since the `formSubmitted` callback is triggered when showing the Crowdsignal completion screen
        // (a GET request).
        if case .formSubmitted = navigationAction.navigationType, navigationAction.request.httpMethod == "POST" {
            onCompletion()
        }

        decisionHandler(.allow)
    }
}
