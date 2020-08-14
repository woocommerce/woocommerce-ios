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
            let surveyMessageTag = queryItems.first(where: { $0.name == Constants.surveyMessageTagKey })?.value else {
                return
        }

        if surveyMessageTag == Constants.surveyCompletionTagValue {
            onCompletion()
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation) {
        removeLoadingView()
    }
}

// MARK: Constants
//
private extension SurveyViewController {
    enum Constants {
        static let surveyMessageTagKey = "msg"
        static let surveyCompletionTagValue = "done"
    }
}
