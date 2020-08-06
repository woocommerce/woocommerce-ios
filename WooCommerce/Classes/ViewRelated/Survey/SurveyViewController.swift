import UIKit
import WebKit

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
    private let loadingView = SurveyLoadingView()

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
        addLoadingView()
        configureAndLoadSurvey()
    }

    private func configureAndLoadSurvey() {
        title = survey.title

        let request = URLRequest(url: survey.url)
        webView.load(request)
        webView.navigationDelegate = self
    }

    /// Adds a loading view to the screen pinned at the center
    ///
    private func addLoadingView() {
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingView)
        view.pinSubviewAtCenter(loadingView)
    }

    /// Removes the loading view from the screen with a fade out animaition
    ///
    private func removeLoadingView() {
        loadingView.fadeOut { [weak self] _ in
            self?.loadingView.removeFromSuperview()
        }
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
                return WooConstants.URLs.inAppFeedback.asURL()
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

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation) {
        removeLoadingView()
    }
}
