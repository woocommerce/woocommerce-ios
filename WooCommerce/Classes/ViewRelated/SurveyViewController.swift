import UIKit
import WebKit

final class SurveyViewController: UIViewController {
    @IBOutlet private weak var webView: WKWebView!

    private let onSurveySubmission: (_ viewController: UIViewController) -> Void

    init(onSurveySubmission: @escaping (_ viewController: UIViewController) -> Void) {
        self.onSurveySubmission = onSurveySubmission
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // TODO-jc: localization comment
        title = NSLocalizedString("How can we improve?", comment: "")

        addCloseNavigationBarButton()

        let request = URLRequest(url: URL(string: "https://wasseryi.survey.fm/woo-mobile-app-test-survey")!)
        webView.load(request)
        webView.navigationDelegate = self
    }
}

extension SurveyViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        switch navigationAction.navigationType {
        case .formSubmitted where navigationAction.request.httpMethod == "POST":
            decisionHandler(.allow)

            onSurveySubmission(self)
        default:
            decisionHandler(.allow)
            break
        }
    }
}
