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
    
    func scheduleLocalNotificationIfEligible() {
        guard featureFlagService.isFeatureFlagEnabled(.pointOfSaleSurveys) else { return }
        guard isCountryEligible() else { return }
        // TODO: Check as well if the notification hasn't been scheduled already WOOMOB-1461

        scheduleLocalNotification(for: .currentMerchant)
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
        // 1. Set in app storage
        // TODO: WOOMOB-1461
        
        // 2. Trigger
        switch merchantType {
        case .potentialMerchant:
            Task { @MainActor in
                let seconds = TimeInterval(60)
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
                let seconds = TimeInterval(60 * 5)
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
