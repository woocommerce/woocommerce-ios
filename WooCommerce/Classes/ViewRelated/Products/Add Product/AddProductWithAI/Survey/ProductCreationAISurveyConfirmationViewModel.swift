import UIKit

/// View model for `ProductCreationAISurveyConfirmationView`.
struct ProductCreationAISurveyConfirmationViewModel {
    private let onStart: () -> Void
    private let onSkip: () -> Void
    private let analytics: Analytics

    init(onStart: @escaping () -> Void,
         onSkip: @escaping () -> Void,
         analytics: Analytics = ServiceLocator.analytics) {
        self.onStart = onStart
        self.onSkip = onSkip
        self.analytics = analytics
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
