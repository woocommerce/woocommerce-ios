import UIKit

/// Coordinates navigation for Free trial survey
///
final class FreeTrialSurveyCoordinator: Coordinator {
    enum Source: String {
        case freeTrialSurvey24hAfterFreeTrialSubscribed = "free_trial_survey_24h_after_free_trial_subscribed"
    }

    let navigationController: UINavigationController

    private let source: Source
    private let analytics: Analytics

    init(source: Source,
         navigationController: UINavigationController,
         analytics: Analytics = ServiceLocator.analytics) {
        self.source = source
        self.navigationController = navigationController
        self.analytics = analytics
    }

    func start() {
        analytics.track(event: .FreeTrialSurvey.surveyDisplayed(source: source))

        let survey = FreeTrialSurveyHostingController(viewModel: .init(source: source,
                                                                       onClose: { [weak self] in
            self?.navigationController.dismiss(animated: true)
        }))
        navigationController.present(WooNavigationController(rootViewController: survey), animated: true)
    }
}
