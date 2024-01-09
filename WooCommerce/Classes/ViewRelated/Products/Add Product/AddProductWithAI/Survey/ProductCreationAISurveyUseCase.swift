import Foundation

/// To determine when to show Product Creation AI survey
///
final class ProductCreationAISurveyUseCase {
    private let defaults: UserDefaults
    private let analytics: Analytics

    init(defaults: UserDefaults = UserDefaults.standard,
         analytics: Analytics = ServiceLocator.analytics) {
        self.defaults = defaults
        self.analytics = analytics
    }

    private(set) var numberOfTimesAIProductCreationAISurveySuggested: Int {
        get {
            defaults.integer(forKey: UserDefaults.Key.numberOfTimesAIProductCreationAISurveySuggested.rawValue)
        }
        set {
            defaults.set(newValue, forKey: UserDefaults.Key.numberOfTimesAIProductCreationAISurveySuggested.rawValue)
        }
    }

    /// Returns `true` if it is time to present Product Creation AI survey.
    ///
    func shouldShowProductCreationAISurvey() -> Bool {
        guard !defaults.bool(forKey: UserDefaults.Key.didStartProductCreationAISurvey.rawValue) else {
            return false
        }
        return numberOfTimesAIProductCreationAISurveySuggested < 2
    }

    /// Increments the survey suggested counter by 1
    ///
    func didSuggestProductCreationAISurvey() {
        numberOfTimesAIProductCreationAISurveySuggested += 1
        analytics.track(event: .ProductCreationAI.Survey.confirmationViewDisplayed())
    }

    /// Saves that user started the survey
    ///
    func didStartProductCreationAISurvey() {
        defaults[.didStartProductCreationAISurvey] = true
    }
}
