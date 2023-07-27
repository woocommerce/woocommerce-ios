import Foundation

extension WooAnalyticsEvent {
    enum FreeTrialSurvey {

        private enum Key: String {
            case source = "source"
            case surveyOption = "survey_option"
            case freeText = "free_text"
        }

        static func surveyDisplayed(source: FreeTrialSurveyCoordinator.Source) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .freeTrialSurveyDisplayed,
                              properties: [Key.source.rawValue: source.rawValue])
        }

        static func surveySent(source: FreeTrialSurveyCoordinator.Source,
                               surveyOption: String,
                               freeText: String?) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .freeTrialSurveySent,
                              properties: [Key.source.rawValue: source.rawValue,
                                           Key.surveyOption.rawValue: surveyOption,
                                           Key.freeText.rawValue: freeText].compactMapValues { $0 })
        }
    }
}
