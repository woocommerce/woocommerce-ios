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
        guard stores.isAuthenticated else { return }

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
        await MainActor.run {
            var isScheduled = false
            let action: AppSettingsAction
            switch merchantType {
            case .potentialMerchant:
                action = AppSettingsAction.getPOSSurveyPotentialMerchantNotificationScheduled { scheduled in
                    isScheduled = scheduled
                }
            case .currentMerchant:
                action = AppSettingsAction.getPOSSurveyCurrentMerchantNotificationScheduled { scheduled in
                    isScheduled = scheduled
                }
            }
            stores.dispatch(action)
            return isScheduled
        }
    }

    private func hasOpenedPOSAtLeastOnce() async -> Bool {
        await MainActor.run {
            var hasOpenedPOS = false
            let action = AppSettingsAction.getHasPOSBeenOpenedAtLeastOnce { hasOpened in
                hasOpenedPOS = hasOpened
            }
            stores.dispatch(action)
            return hasOpenedPOS
        }
    }

    private func scheduleLocalNotification(for merchantType: POSNotificationScheduler.MerchantType) async {
        guard let surveyURL = URL(string: merchantType.surveyURL) else {
            assertionFailure("Invalid POS survey URL: \(merchantType.surveyURL)")
            return
        }

        let sessionManager = stores.sessionManager
        let taggedSurveyURL = surveyURL
            .tagPlatform("ios")
            .tagAppVersion(Bundle.main.bundleVersion())
            .tagSiteInfo(siteID: sessionManager.defaultSite?.siteID,
                         storeUUID: sessionManager.defaultStoreUUID,
                         storeURL: sessionManager.defaultSite?.url)

        let payload: [AnyHashable: Any] = [
            LocalNotification.UserInfoKey.surveyURL: taggedSurveyURL.absoluteString
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

        await MainActor.run {
            let action: AppSettingsAction
            switch merchantType {
            case .potentialMerchant:
                action = AppSettingsAction.setPOSSurveyPotentialMerchantNotificationScheduled { _ in }
            case .currentMerchant:
                action = AppSettingsAction.setPOSSurveyCurrentMerchantNotificationScheduled { _ in }
            }
            stores.dispatch(action)
        }
    }
}
