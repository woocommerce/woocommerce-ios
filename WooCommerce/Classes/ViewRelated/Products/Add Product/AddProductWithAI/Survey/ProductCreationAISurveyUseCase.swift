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

    var numberOfTimesAIProductCreated: Int {
        get {
            defaults.integer(forKey: UserDefaults.Key.numberOfTimesAIProductCreated.rawValue)
        }
        set {
            defaults.set(newValue, forKey: UserDefaults.Key.numberOfTimesAIProductCreated.rawValue)
        }
    }

    /// Returns `true` if it is time to present Product Creation AI survey.
    ///
    func shouldShowProductCreationAISurvey() -> Bool {
        guard numberOfTimesAIProductCreated >= 3 else {
            return false
        }
        return !defaults.bool(forKey: UserDefaults.Key.didSuggestProductCreationAISurvey.rawValue)
    }

    /// Saves that we have asked the user to provide feedback in survey
    ///
    func didSuggestProductCreationAISurvey() {
        analytics.track(event: .ProductCreationAI.Survey.confirmationViewDisplayed())
        defaults[.didSuggestProductCreationAISurvey] = true
    }
}
