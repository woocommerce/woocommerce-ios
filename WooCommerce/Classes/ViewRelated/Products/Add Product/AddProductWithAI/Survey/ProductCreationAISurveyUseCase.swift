import Foundation
import protocol WooFoundation.Analytics

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

    private var numberOfTimesProductCreationAISurveySuggested: Int {
        get {
            defaults.integer(forKey: UserDefaults.Key.numberOfTimesProductCreationAISurveySuggested.rawValue)
        }
        set {
            defaults.set(newValue, forKey: UserDefaults.Key.numberOfTimesProductCreationAISurveySuggested.rawValue)
        }
    }

    /// Returns `true` if Survey has been suggested before
    ///
    func haveSuggestedSurveyBefore() -> Bool {
        numberOfTimesProductCreationAISurveySuggested > 0
    }

    /// Returns `true` if it is time to present Product Creation AI survey.
    ///
    func shouldShowProductCreationAISurvey() -> Bool {
        guard !defaults.bool(forKey: UserDefaults.Key.didStartProductCreationAISurvey.rawValue) else {
            return false
        }
        return numberOfTimesProductCreationAISurveySuggested < 2
    }

    /// Increments the survey suggested counter by 1
    ///
    func didSuggestProductCreationAISurvey() {
        numberOfTimesProductCreationAISurveySuggested += 1
        analytics.track(event: .ProductCreationAI.Survey.confirmationViewDisplayed())
    }

    /// Saves that user started the survey
    ///
    func didStartProductCreationAISurvey() {
        defaults[.didStartProductCreationAISurvey] = true
    }
}
