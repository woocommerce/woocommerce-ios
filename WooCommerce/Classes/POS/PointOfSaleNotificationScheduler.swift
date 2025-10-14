import Foundation
import UserNotifications
import Yosemite
import Experiments

// periphery: ignore - work in progress
protocol PointOfSaleNotificationScheduling {
    func scheduleLocalNotificationIfEligible(for merchantType: PointOfSaleNotificationScheduler.MerchantType) async
}

// periphery: ignore - work in progress
final class PointOfSaleNotificationScheduler: PointOfSaleNotificationScheduling {
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

    private let stores: StoresManager
    private let siteSettings: [SiteSetting]
    private let featureFlagService: FeatureFlagService
    private let pushNotificationsManager: PushNotesManager

    init(stores: StoresManager = ServiceLocator.stores,
         siteSettings: [SiteSetting] = ServiceLocator.selectedSiteSettings.siteSettings,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         pushNotificationsManager: PushNotesManager = ServiceLocator.pushNotesManager) {
        self.stores = stores
        self.siteSettings = siteSettings
        self.featureFlagService = featureFlagService
        self.pushNotificationsManager = pushNotificationsManager
    }

    func scheduleLocalNotificationIfEligible(for merchantType: PointOfSaleNotificationScheduler.MerchantType) async {
        guard featureFlagService.isFeatureFlagEnabled(.pointOfSaleSurveys) else { return }

        let isScheduled = await withCheckedContinuation { continuation in
            let action = AppSettingsAction.getPOSSurveyNotificationScheduled { isScheduled in
                continuation.resume(returning: isScheduled)
            }
            stores.dispatch(action)
        }
        guard !isScheduled else { return }
        guard isCountryEligible() else { return }

        await scheduleLocalNotification(for: merchantType)
    }

    private func isCountryEligible() -> Bool {
        let storeCountry = SiteAddress(siteSettings: siteSettings).countryCode
        if storeCountry == .US || storeCountry == .GB {
            return true
        } else {
            return false
        }
    }

    private func scheduleLocalNotification(for merchantType: PointOfSaleNotificationScheduler.MerchantType) async {

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

        await withCheckedContinuation { continuation in
            let action = AppSettingsAction.setPOSSurveyNotificationScheduled { _ in
                continuation.resume()
            }
            stores.dispatch(action)
        }
    }
}
