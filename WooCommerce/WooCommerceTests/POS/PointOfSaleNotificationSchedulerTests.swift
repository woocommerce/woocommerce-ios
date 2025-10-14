import Testing
import UserNotifications
@testable import WooCommerce
@testable import Yosemite

struct PointOfSaleNotificationSchedulerTests {
    private let mockFeatureFlagService: MockFeatureFlagService
    private let mockPushNotesManager: MockPushNotificationsManager

    init() {
        mockFeatureFlagService = MockFeatureFlagService()
        mockPushNotesManager = MockPushNotificationsManager()
    }

    @Test func scheduleLocalNotificationIfEligible_when_featureFlag_is_disabled_then_no_notification_scheduled() async throws {
        // Given
        let siteSettings = sampleSiteSettings(countryCode: "US")
        mockFeatureFlagService.isFeatureFlagEnabledReturnValue[.pointOfSaleSurveys] = false

        let scheduler = PointOfSaleNotificationScheduler(
            siteSettings: siteSettings,
            featureFlagService: mockFeatureFlagService,
            pushNotificationsManager: mockPushNotesManager
        )

        // When
        await scheduler.scheduleLocalNotificationIfEligible(for: .potentialMerchant)

        // Then
        #expect(mockPushNotesManager.requestedLocalNotifications.isEmpty)
    }

    @Test func scheduleLocalNotificationIfEligible_when_country_is_US_and_featureFlag_is_enabled_then_notification_is_scheduled() async throws {
        // Given
        let siteSettings = sampleSiteSettings(countryCode: "US")
        mockFeatureFlagService.isFeatureFlagEnabledReturnValue[.pointOfSaleSurveys] = true

        let scheduler = PointOfSaleNotificationScheduler(
            siteSettings: siteSettings,
            featureFlagService: mockFeatureFlagService,
            pushNotificationsManager: mockPushNotesManager
        )

        // When/Then
        await confirmation() { confirmation in
            mockPushNotesManager.onRequestLocalNotificationCalled = {
                confirmation()
            }
            await scheduler.scheduleLocalNotificationIfEligible(for: .potentialMerchant)
        }

        #expect(mockPushNotesManager.requestedLocalNotifications.count == 1)
    }

    @Test func scheduleLocalNotificationIfEligible_when_country_is_GB_and_featureFlag_is_enabled_then_notification_is_scheduled() async throws {
        // Given
        let siteSettings = sampleSiteSettings(countryCode: "GB")
        mockFeatureFlagService.isFeatureFlagEnabledReturnValue[.pointOfSaleSurveys] = true

        let scheduler = PointOfSaleNotificationScheduler(
            siteSettings: siteSettings,
            featureFlagService: mockFeatureFlagService,
            pushNotificationsManager: mockPushNotesManager
        )

        // When/Then
        await confirmation() { confirmation in
            mockPushNotesManager.onRequestLocalNotificationCalled = {
                confirmation()
            }
            await scheduler.scheduleLocalNotificationIfEligible(for: .potentialMerchant)
        }

        #expect(mockPushNotesManager.requestedLocalNotifications.count == 1)
    }

    @Test func scheduleLocalNotificationIfEligible_when_country_is_not_eligible_then_no_notification_scheduled() async throws {
        // Given
        let siteSettings = sampleSiteSettings(countryCode: "FR")
        mockFeatureFlagService.isFeatureFlagEnabledReturnValue[.pointOfSaleSurveys] = true

        let scheduler = PointOfSaleNotificationScheduler(
            siteSettings: siteSettings,
            featureFlagService: mockFeatureFlagService,
            pushNotificationsManager: mockPushNotesManager
        )

        // When
        await scheduler.scheduleLocalNotificationIfEligible(for: .potentialMerchant)

        // Then
        #expect(mockPushNotesManager.requestedLocalNotifications.isEmpty)
    }

    @Test func scheduleLocalNotificationIfEligible_when_potentialMerchant_then_uses_correct_scenario() async throws {
        // Given
        let siteSettings = sampleSiteSettings(countryCode: "US")
        mockFeatureFlagService.isFeatureFlagEnabledReturnValue[.pointOfSaleSurveys] = true

        let scheduler = PointOfSaleNotificationScheduler(
            siteSettings: siteSettings,
            featureFlagService: mockFeatureFlagService,
            pushNotificationsManager: mockPushNotesManager
        )

        // When/Then
        await confirmation() { confirmation in
            mockPushNotesManager.onRequestLocalNotificationCalled = {
                confirmation()
            }
            await scheduler.scheduleLocalNotificationIfEligible(for: .potentialMerchant)
        }

        let notification = try #require(mockPushNotesManager.requestedLocalNotifications.first)
        let trigger = try #require(mockPushNotesManager.triggersForRequestedLocalNotifications.first as? UNTimeIntervalNotificationTrigger)

        #expect(notification.scenario == .pointOfSalePotentialMerchant)
        #expect(notification.userInfo[LocalNotification.UserInfoKey.surveyURL] as? String ==
                LocalNotification.SurveyURL.pointOfSalePotentialMerchant)
        #expect(trigger.timeInterval == 60)
        #expect(trigger.repeats == false)
    }

    @Test func scheduleLocalNotificationIfEligible_when_currentMerchant_then_correctScenario() async throws {
        // Given
        let siteSettings = sampleSiteSettings(countryCode: "US")
        mockFeatureFlagService.isFeatureFlagEnabledReturnValue[.pointOfSaleSurveys] = true

        let scheduler = PointOfSaleNotificationScheduler(
            siteSettings: siteSettings,
            featureFlagService: mockFeatureFlagService,
            pushNotificationsManager: mockPushNotesManager
        )

        // When/Then
        await confirmation() { confirmation in
            mockPushNotesManager.onRequestLocalNotificationCalled = {
                confirmation()
            }
            await scheduler.scheduleLocalNotificationIfEligible(for: .currentMerchant)
        }

        let notification = try #require(mockPushNotesManager.requestedLocalNotifications.first)
        let trigger = try #require(mockPushNotesManager.triggersForRequestedLocalNotifications.first as? UNTimeIntervalNotificationTrigger)

        #expect(notification.scenario == .pointOfSaleCurrentMerchant)
        #expect(notification.userInfo[LocalNotification.UserInfoKey.surveyURL] as? String ==
                LocalNotification.SurveyURL.pointOfSaleCurrentMerchant)
        #expect(trigger.timeInterval == 300)
        #expect(trigger.repeats == false)
    }

    @Test func scheduleLocalNotificationIfEligible_when_eligible_then_notification_manager_receives_correct_notification() async throws {
        // Given
        let siteSettings = sampleSiteSettings(countryCode: "GB")
        mockFeatureFlagService.isFeatureFlagEnabledReturnValue[.pointOfSaleSurveys] = true

        let scheduler = PointOfSaleNotificationScheduler(
            siteSettings: siteSettings,
            featureFlagService: mockFeatureFlagService,
            pushNotificationsManager: mockPushNotesManager
        )

        // When/Then
        await confirmation() { confirmation in
            mockPushNotesManager.onRequestLocalNotificationCalled = {
                confirmation()
            }
            await scheduler.scheduleLocalNotificationIfEligible(for: .potentialMerchant)
        }

        #expect(mockPushNotesManager.requestedLocalNotifications.count == 1)
        #expect(mockPushNotesManager.triggersForRequestedLocalNotifications.count == 1)

        let notification = try #require(mockPushNotesManager.requestedLocalNotifications.first)
        #expect(notification.scenario == .pointOfSalePotentialMerchant)
        #expect(notification.userInfo.keys.contains(LocalNotification.UserInfoKey.surveyURL))
    }

    private func sampleSiteSettings(countryCode: String) -> [SiteSetting] {
        [
            SiteSetting.fake().copy(
                siteID: 123,
                settingID: "woocommerce_default_country",
                value: countryCode,
                settingGroupKey: SiteSettingGroup.general.rawValue
            )
        ]
    }
}
