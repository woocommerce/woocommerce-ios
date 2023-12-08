import UIKit

/// View model for `ProductCreationAISurveyConfirmationView`.
struct ProductCreationAISurveyConfirmationViewModel {
    private let onTappingStartTheSurvey: () -> Void
    private let onTappingSkip: () -> Void
    private let analytics: Analytics

    init(onTappingStartTheSurvey: @escaping () -> Void,
         onTappingSkip: @escaping () -> Void,
         analytics: Analytics = ServiceLocator.analytics) {
        self.onTappingStartTheSurvey = onTappingStartTheSurvey
        self.onTappingSkip = onTappingSkip
        self.analytics = analytics
    }

    func didTapStartTheSurvey() {
        analytics.track(event: .ProductCreationAI.Survey.startSurvey())
        onTappingStartTheSurvey()
    }

    func didTapSkip() {
        analytics.track(event: .ProductCreationAI.Survey.skip())
        onTappingSkip()
    }
}
