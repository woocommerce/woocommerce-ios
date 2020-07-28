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
    private let survey: SurveySource

    init(survey: SurveySource) {
        self.survey = survey
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
    }
}

// MARK: Survey Configuration
//
extension SurveyViewController {
    enum SurveySource {
        case inAppFeedback

        var url: URL {
            switch self {
            case .inAppFeedback:
                return WooConstants.inAppFeedbackURL
            }
        }

        var title: String {
            switch self {
            case .inAppFeedback:
                return NSLocalizedString("How can we improve?", comment: "Title on the navigation bar for the in-app feedback survey")
            }
        }
    }
}
