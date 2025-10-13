import Foundation
import UserNotifications
import Yosemite
import Experiments

final class PointOfSaleNotificationScheduler {
    enum MerchantType {
        case potentialMerchant
        case currentMerchant
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
        switch merchantType {
        case .potentialMerchant:
            Task { @MainActor in
                let seconds = TimeInterval(Constants.potentialMerchantNotificationTimeIntervalInSeconds)
                let payload: [AnyHashable: Any] = [
                    LocalNotification.UserInfoKey.surveyURL: LocalNotification.SurveyURL.pointOfSalePotentialMerchant
                ]
                let notification = LocalNotification(
                    title: LocalNotification.Localization.PointOfSalePotentialMerchant.title,
                    body: LocalNotification.Localization.PointOfSalePotentialMerchant.body,
                    scenario: .pointOfSalePotentialMerchant,
                    actions: nil,
                    userInfo: payload
                )
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
                await pushNotificationsManager.requestLocalNotification(notification, trigger: trigger)
            }
        case .currentMerchant:
            Task { @MainActor in
                let seconds = TimeInterval(Constants.currentMerchantNotificationTimeIntervalInSeconds)
                let payload: [AnyHashable: Any] = [
                    LocalNotification.UserInfoKey.surveyURL: LocalNotification.SurveyURL.pointOfSaleCurrentMerchant
                ]
                let notification = LocalNotification(
                    title: LocalNotification.Localization.PointOfSaleCurrentMerchant.title,
                    body: LocalNotification.Localization.PointOfSaleCurrentMerchant.body,
                    scenario: .pointOfSaleCurrentMerchant,
                    actions: nil,
                    userInfo: payload
                )
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
                await pushNotificationsManager.requestLocalNotification(notification, trigger: trigger)
            }
        }
    }
}

private extension PointOfSaleNotificationScheduler {
    enum Constants {
        static let potentialMerchantNotificationTimeIntervalInSeconds: Int = 60
        static let currentMerchantNotificationTimeIntervalInSeconds: Int = 60 * 5
    }
}
