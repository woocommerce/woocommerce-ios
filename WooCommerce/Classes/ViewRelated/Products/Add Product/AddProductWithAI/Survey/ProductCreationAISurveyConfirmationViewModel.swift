import UIKit
import protocol WooFoundation.Analytics

/// View model for `ProductCreationAISurveyConfirmationView`.
struct ProductCreationAISurveyConfirmationViewModel {
    private let onStart: () -> Void
    private let onSkip: () -> Void
    private let analytics: Analytics
    let skipButtonTitle: String

    init(onStart: @escaping () -> Void,
         onSkip: @escaping () -> Void,
         analytics: Analytics = ServiceLocator.analytics) {
        self.onStart = onStart
        self.onSkip = onSkip
        self.analytics = analytics
        let useCase = ProductCreationAISurveyUseCase()
        skipButtonTitle = useCase.haveSuggestedSurveyBefore() ? Localization.dontShowItAgain : Localization.remindMeLater
    }

    func didTapStartTheSurvey() {
        analytics.track(event: .ProductCreationAI.Survey.startSurvey())
        onStart()
    }

    func didTapSkip() {
        analytics.track(event: .ProductCreationAI.Survey.skip())
        onSkip()
    }
}

private extension ProductCreationAISurveyConfirmationViewModel {
    enum Localization {
        static let remindMeLater = NSLocalizedString("productCreationAISurveyConfirmationViewModel.remindMeLater",
                                                     value: "Remind Me Later",
                                                     comment: "Dismiss button title in Product Creation AI survey confirmation view.")

        static let dontShowItAgain = NSLocalizedString("productCreationAISurveyConfirmationViewModel.dontShowItAgain",
                                                       value: "Don’t Show it Again",
                                                       comment: "Dismiss button title in Product Creation AI survey confirmation view.")
    }
}
