import UIKit

/// Controls navigation for the in-app feedback flow. Meant to be presented modally
///
final class SurveyCoordinatingController: WooNavigationController {

    /// Used to present the Contact Support dialog
    private let zendeskManager: ZendeskManagerProtocol

    /// Factory that creates view controllers needed for this flow
    private let viewControllersFactory: SurveyViewControllersFactoryProtocol

    private let analytics: Analytics

    /// Is true when `self` is being dismissed because the user has finished the survey.
    private var receivedSurveyFinishedEvent: Bool = false

    /// What kind of survey to present.
    private let survey: SurveyViewController.Source

    init(survey: SurveyViewController.Source,
         zendeskManager: ZendeskManagerProtocol = ZendeskProvider.shared,
         viewControllersFactory: SurveyViewControllersFactoryProtocol = SurveyViewControllersFactory(),
         analytics: Analytics = ServiceLocator.analytics) {
        self.survey = survey
        self.zendeskManager = zendeskManager
        self.viewControllersFactory = viewControllersFactory
        self.analytics = analytics
        super.init(nibName: nil, bundle: nil)
        startSurveyNavigation()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if isBeingDismissed && !receivedSurveyFinishedEvent {
            analytics.track(event: .surveyScreen(context: survey.feedbackContextForEvents, action: .canceled))
        }
    }
}

// MARK: Navigation
private extension SurveyCoordinatingController {

    /// Starts navigation with `SurveyViewController` as root view controller.
    ///
    func startSurveyNavigation() {
        analytics.track(event: .surveyScreen(context: survey.feedbackContextForEvents, action: .opened))

        let surveyViewController = viewControllersFactory.makeSurveyViewController(survey: survey) { [weak self] in
            guard let self = self else {
                return
            }

            self.receivedSurveyFinishedEvent = true
            self.analytics.track(event: .surveyScreen(context: self.survey.feedbackContextForEvents,
                                                      action: .completed))

            self.navigateToSurveySubmitted()
        }
        setViewControllers([surveyViewController], animated: false)
    }

    /// Proceeds navigation to `SurveySubmittedViewController`
    ///
    func navigateToSurveySubmitted() {
        let completionViewController = viewControllersFactory.makeSurveySubmittedViewController(onContactUsAction: { [weak self] in
            guard let self = self else {
                return
            }
            self.zendeskManager.showNewRequestIfPossible(from: self, with: nil)
        }, onBackToStoreAction: { [weak self] in
            self?.finishSurveyNavigation()
        })
        setViewControllers([completionViewController], animated: true)
    }

    /// Dismisses the flow modally
    ///
    func finishSurveyNavigation() {
        dismiss(animated: true)
    }
}
