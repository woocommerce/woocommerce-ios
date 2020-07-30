import UIKit

/// Controls navigation for the in-app feedback flow. Meant to be presented modally
///
final class SurveyNavigationController: WooNavigationController {

    /// Used to present the Contact Support dialog
    private let zendeskManager: ZendeskManagerProtocol

    init(survey: SurveyViewController.Source, zendeskManager: ZendeskManagerProtocol = ZendeskManager.shared) {
        self.zendeskManager = zendeskManager
        super.init(navigationBarClass: nil, toolbarClass: nil)
        startSurveyNavigation(survey: survey)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: Navigation
private extension SurveyNavigationController {

    /// Starts navigation with `SurveyViewController` as root view controller.
    ///
    func startSurveyNavigation(survey: SurveyViewController.Source) {
        let surveyViewController = SurveyViewController(survey: survey, onCompletion: { [weak self] in
            self?.navigateToSurveySubmitted()
        })
        setViewControllers([surveyViewController], animated: false)
    }

    /// Proceeds navigation to `SurveySubmittedViewController`
    ///
    func navigateToSurveySubmitted() {
        let completionViewController = SurveySubmittedViewController()

        completionViewController.onContactUsAction = { [weak self] in
            guard let self = self else {
                return
            }
            self.zendeskManager.showNewRequestIfPossible(from: self, with: nil)
        }

        completionViewController.onBackToStoreAction = { [weak self] in
            self?.finishSurveyNavigation()
        }

        show(completionViewController, sender: self)
    }

    /// Dismisses the flow modally
    ///
    func finishSurveyNavigation() {
        dismiss(animated: true)
    }
}
