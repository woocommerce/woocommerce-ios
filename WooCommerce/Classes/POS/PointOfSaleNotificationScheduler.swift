import Foundation
import UserNotifications
import Yosemite
import Experiments
// periphery: ignore - work in progress
final class PointOfSaleNotificationScheduler {
    enum MerchantType {
        case potentialMerchant
        case currentMerchant

        var scenario: LocalNotification.Scenario {
            switch self {
            case .potentialMerchant:
                return .pointOfSalePotentialMerchant
            case .currentMerchant:
                return .pointOfSaleCurrentMerchant
            }
        }

        var surveyURL: String {
            switch self {
            case .potentialMerchant:
                return LocalNotification.SurveyURL.pointOfSalePotentialMerchant
            case .currentMerchant:
                return LocalNotification.SurveyURL.pointOfSaleCurrentMerchant
            }
        }

        var timeIntervalInSeconds: Int {
            switch self {
            case .potentialMerchant:
                return 60
            case .currentMerchant:
                return 60 * 5
            }
        }

        var timeInterval: TimeInterval {
            TimeInterval(timeIntervalInSeconds)
        }
    }

    private let siteSettings: [SiteSetting]
    private let featureFlagService: FeatureFlagService
    private let pushNotificationsManager: PushNotesManager

    init(siteSettings: [SiteSetting] = ServiceLocator.selectedSiteSettings.siteSettings,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         pushNotificationsManager: PushNotesManager = ServiceLocator.pushNotesManager) {
        self.siteSettings = siteSettings
        self.featureFlagService = featureFlagService
        self.pushNotificationsManager = pushNotificationsManager
    }

    func scheduleLocalNotificationIfEligible(for merchantType: PointOfSaleNotificationScheduler.MerchantType) {
        // TODO: Additional check to see if .currentMerchant case has used POS before - WOOMOB-1498
        // TODO: Check as well if the notification hasn't been scheduled already WOOMOB-1461
        guard featureFlagService.isFeatureFlagEnabled(.pointOfSaleSurveys) else { return }
        guard isCountryEligible() else { return }

        scheduleLocalNotification(for: merchantType)
    }

    private func isCountryEligible() -> Bool {
        let storeCountry = SiteAddress(siteSettings: siteSettings).countryCode
        if storeCountry == .US || storeCountry == .GB {
            return true
        } else {
            return false
        }
    }

    private func scheduleLocalNotification(for merchantType: PointOfSaleNotificationScheduler.MerchantType) {
        // TODO: Set scheduled notification value in app storage - WOOMOB-1461
        Task { @MainActor in
            let payload: [AnyHashable: Any] = [
                LocalNotification.UserInfoKey.surveyURL: merchantType.surveyURL
            ]

            let notification = LocalNotification(
                scenario: merchantType.scenario,
                userInfo: payload
            )

            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: merchantType.timeInterval,
                repeats: false
            )

            await pushNotificationsManager.requestLocalNotification(notification, trigger: trigger)
        }
    }
}
