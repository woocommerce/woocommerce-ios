import Foundation
import UserNotifications
import Yosemite
import Experiments

protocol POSNotificationScheduling {
    func scheduleLocalNotificationIfEligible(for merchantType: POSNotificationScheduler.MerchantType) async
}

final class POSNotificationScheduler: POSNotificationScheduling {
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

    func scheduleLocalNotificationIfEligible(for merchantType: POSNotificationScheduler.MerchantType) async {
        let isScheduled = await isNotificationAlreadyScheduled(for: merchantType)
        guard !isScheduled else { return }
        guard isCountryEligible() else { return }

        // For current merchants, also check if they've opened POS at least once
        if merchantType == .currentMerchant {
            let hasOpenedPOS = await hasOpenedPOSAtLeastOnce()
            guard hasOpenedPOS else { return }
        }

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

    private func isNotificationAlreadyScheduled(for merchantType: MerchantType) async -> Bool {
        // Check if the specific notification type is already scheduled
        let isCurrentMerchantTypeScheduled = await checkIfScheduled(for: merchantType)
        if isCurrentMerchantTypeScheduled {
            return true
        }

        // Don't schedule notification for potential merchant if the user is already marked as current merchant
        guard merchantType == .potentialMerchant else {
            return false
        }

        let isCurrentMerchantScheduled = await checkIfScheduled(for: .currentMerchant)
        return isCurrentMerchantScheduled
    }

    private func checkIfScheduled(for merchantType: MerchantType) async -> Bool {
        await withCheckedContinuation { continuation in
            let action: AppSettingsAction
            switch merchantType {
            case .potentialMerchant:
                action = AppSettingsAction.getPOSSurveyPotentialMerchantNotificationScheduled { isScheduled in
                    continuation.resume(returning: isScheduled)
                }
            case .currentMerchant:
                action = AppSettingsAction.getPOSSurveyCurrentMerchantNotificationScheduled { isScheduled in
                    continuation.resume(returning: isScheduled)
                }
            }
            Task { @MainActor in
                stores.dispatch(action)
            }
        }
    }

    private func hasOpenedPOSAtLeastOnce() async -> Bool {
        await withCheckedContinuation { continuation in
            let action = AppSettingsAction.getHasPOSBeenOpenedAtLeastOnce { hasOpened in
                continuation.resume(returning: hasOpened)
            }
            Task { @MainActor in
                stores.dispatch(action)
            }
        }
    }

    private func scheduleLocalNotification(for merchantType: POSNotificationScheduler.MerchantType) async {

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
            let action: AppSettingsAction
            switch merchantType {
            case .potentialMerchant:
                action = AppSettingsAction.setPOSSurveyPotentialMerchantNotificationScheduled { _ in
                    continuation.resume()
                }
            case .currentMerchant:
                action = AppSettingsAction.setPOSSurveyCurrentMerchantNotificationScheduled { _ in
                    continuation.resume()
                }
            }
            Task { @MainActor in
                stores.dispatch(action)
            }
        }
    }
}
