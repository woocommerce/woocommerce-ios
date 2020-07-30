import UIKit

/// Controls navigation for the in-app feedback flow. Meant to be presented modally
///
final class SurveyNavigationController: WooNavigationController {

    init(survey: SurveyViewController.Source) {
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
    func startSurveyNavigation(survey: SurveyViewController.Source) {
        let surveyViewController = SurveyViewController(survey: survey, onCompletion: { [weak self] in
            self?.navigateToSurveySubmitted()
        })
        setViewControllers([surveyViewController], animated: false)
    }

    /// Proceeds navigation to `SurveySubmittedViewController`
    func navigateToSurveySubmitted() {
        let completionViewController = SurveySubmittedViewController()
        show(completionViewController, sender: self)
    }
}
