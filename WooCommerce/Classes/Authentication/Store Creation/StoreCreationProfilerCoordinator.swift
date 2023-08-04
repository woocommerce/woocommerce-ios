import UIKit

final class StoreCreationProfilerCoordinator: Coordinator {
    let navigationController: UINavigationController

    private let analytics: Analytics

    init(navigationController: UINavigationController,
         analytics: Analytics = ServiceLocator.analytics) {
        self.navigationController = navigationController
        self.analytics = analytics
    }

    func start() {
        // TODO
    }
}

private extension StoreCreationProfilerCoordinator {
    func showChallengesQuestion(from navigationController: UINavigationController) {
        let questionController = StoreCreationChallengesQuestionHostingController(viewModel:
                .init { _ in
                    // TODO: 10376 - Navigate to features selection and pass the selected challenges
                } onSkip: { [weak self] in
                    guard let self else { return }
                    self.analytics.track(event: .StoreCreation.siteCreationProfilerQuestionSkipped(step: .profilerChallengesQuestion))
                    // TODO: 10376 - Navigate to features selection
                })
        navigationController.pushViewController(questionController, animated: true)
        analytics.track(event: .StoreCreation.siteCreationStep(step: .profilerChallengesQuestion))
    }

    func showFeaturesQuestion(from navigationController: UINavigationController) {
        let questionController = StoreCreationFeaturesQuestionHostingController(viewModel:
                .init { _ in
                    // TODO: 10376 - Navigate to [progress view / my store tab] and pass the selected features
                } onSkip: { [weak self] in
                    guard let self else { return }
                    self.analytics.track(event: .StoreCreation.siteCreationProfilerQuestionSkipped(step: .profilerFeaturesQuestion))
                    // TODO: 10376 - Navigate to [progress view / my store tab]
                })
        navigationController.pushViewController(questionController, animated: true)
        analytics.track(event: .StoreCreation.siteCreationStep(step: .profilerFeaturesQuestion))
    }
}
