import Testing
import UserNotifications
@testable import WooCommerce
@testable import Yosemite

@MainActor
struct POSNotificationSchedulerTests {
    private static let siteID: Int64 = 123
    private static let storeUUID = "8363cd24-2501-463f-b21b-649315a0d507"
    private static let storeURL = "https://example.com"
    private let mockFeatureFlagService: MockFeatureFlagService
    private let mockPushNotesManager: MockPushNotificationsManager
    private let mockStores: MockStoresManager

    init() async throws {
        mockFeatureFlagService = MockFeatureFlagService()
        mockPushNotesManager = MockPushNotificationsManager()
        let site = Site.fake().copy(siteID: Self.siteID, url: Self.storeURL)
        mockStores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true,
                                                                       defaultSite: site,
                                                                       defaultStoreUUID: Self.storeUUID))
    }

    @Test func scheduleLocalNotificationIfEligible_when_country_is_US_then_notification_is_scheduled() async throws {
        // Given
        let siteSettings = sampleSiteSettings(countryCode: "US")
        setupMockStores()

        let scheduler = POSNotificationScheduler(
            stores: mockStores,
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

    @Test func scheduleLocalNotificationIfEligible_when_country_is_GB_then_notification_is_scheduled() async throws {
        // Given
        let siteSettings = sampleSiteSettings(countryCode: "GB")
        setupMockStores()

        let scheduler = POSNotificationScheduler(
            stores: mockStores,
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
        setupMockStores()

        let scheduler = POSNotificationScheduler(
            stores: mockStores,
            siteSettings: siteSettings,
            featureFlagService: mockFeatureFlagService,
            pushNotificationsManager: mockPushNotesManager
        )

        // When
        await scheduler.scheduleLocalNotificationIfEligible(for: .potentialMerchant)

        // Then
        #expect(mockPushNotesManager.requestedLocalNotifications.isEmpty)
    }

    @Test func scheduleLocalNotificationIfEligible_when_stores_are_not_authenticated_then_no_notification_scheduled() async throws {
        // Given
        let siteSettings = sampleSiteSettings(countryCode: "US")
        let mockStores = MockStoresManager(sessionManager: .makeForTesting(authenticated: false))

        let scheduler = POSNotificationScheduler(
            stores: mockStores,
            siteSettings: siteSettings,
            featureFlagService: mockFeatureFlagService,
            pushNotificationsManager: mockPushNotesManager
        )

        // When
        await scheduler.scheduleLocalNotificationIfEligible(for: .potentialMerchant)

        // Then
        #expect(mockPushNotesManager.requestedLocalNotifications.isEmpty)
        #expect(mockStores.receivedActions.isEmpty)
    }

    @Test func scheduleLocalNotificationIfEligible_when_store_action_is_not_handled_then_uses_safe_defaults() async throws {
        // Given
        let siteSettings = sampleSiteSettings(countryCode: "US")

        let scheduler = POSNotificationScheduler(
            stores: mockStores,
            siteSettings: siteSettings,
            featureFlagService: mockFeatureFlagService,
            pushNotificationsManager: mockPushNotesManager
        )

        // When
        await scheduler.scheduleLocalNotificationIfEligible(for: .currentMerchant)

        // Then
        #expect(mockPushNotesManager.requestedLocalNotifications.isEmpty)
    }

    @Test func scheduleLocalNotificationIfEligible_when_potentialMerchant_case_then_uses_correct_scenario() async throws {
        // Given
        let siteSettings = sampleSiteSettings(countryCode: "US")
        setupMockStores()

        let scheduler = POSNotificationScheduler(
            stores: mockStores,
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
                taggedSurveyURL(for: LocalNotification.SurveyURL.pointOfSalePotentialMerchant).absoluteString)
        #expect(trigger.timeInterval == 60)
        #expect(trigger.repeats == false)
    }

    @Test func scheduleLocalNotificationIfEligible_when_currentMerchant_case_then_uses_correct_scenario() async throws {
        // Given
        let siteSettings = sampleSiteSettings(countryCode: "US")
        setupMockStores(hasPOSBeenOpened: true) // Current merchant requires POS to have been opened

        let scheduler = POSNotificationScheduler(
            stores: mockStores,
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
                taggedSurveyURL(for: LocalNotification.SurveyURL.pointOfSaleCurrentMerchant).absoluteString)
        #expect(trigger.timeInterval == 300)
        #expect(trigger.repeats == false)
    }

    @Test func scheduleLocalNotificationIfEligible_when_store_metadata_is_available_then_tags_survey_URL() async throws {
        // Given
        let siteSettings = sampleSiteSettings(countryCode: "US")
        setupMockStores()

        let scheduler = POSNotificationScheduler(
            stores: mockStores,
            siteSettings: siteSettings,
            featureFlagService: mockFeatureFlagService,
            pushNotificationsManager: mockPushNotesManager
        )

        // When
        await scheduler.scheduleLocalNotificationIfEligible(for: .potentialMerchant)

        // Then
        let notification = try #require(mockPushNotesManager.requestedLocalNotifications.first)
        let surveyURL = try #require(notification.userInfo[LocalNotification.UserInfoKey.surveyURL] as? String)
        let components = try #require(URLComponents(string: surveyURL))
        let queryItems = try #require(components.queryItems)

        #expect(queryItems.first(where: { $0.name == "woo-mobile-platform" })?.value == "ios")
        #expect(queryItems.first(where: { $0.name == "app-version" })?.value == Bundle.main.bundleVersion())
        #expect(queryItems.first(where: { $0.name == "site-id" })?.value == "\(Self.siteID)")
        #expect(queryItems.first(where: { $0.name == "store-id" })?.value == Self.storeUUID)
        #expect(queryItems.first(where: { $0.name == "store-url" })?.value == Self.storeURL)
    }

    @Test func scheduleLocalNotificationIfEligible_when_store_metadata_is_unavailable_then_tags_platform_and_app_version() async throws {
        // Given
        let siteSettings = sampleSiteSettings(countryCode: "US")
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        setupMockStores(stores: stores)

        let scheduler = POSNotificationScheduler(
            stores: stores,
            siteSettings: siteSettings,
            featureFlagService: mockFeatureFlagService,
            pushNotificationsManager: mockPushNotesManager
        )

        // When
        await scheduler.scheduleLocalNotificationIfEligible(for: .potentialMerchant)

        // Then
        let notification = try #require(mockPushNotesManager.requestedLocalNotifications.first)
        let surveyURL = try #require(notification.userInfo[LocalNotification.UserInfoKey.surveyURL] as? String)
        let components = try #require(URLComponents(string: surveyURL))
        let queryItems = try #require(components.queryItems)

        #expect(queryItems.first(where: { $0.name == "woo-mobile-platform" })?.value == "ios")
        #expect(queryItems.first(where: { $0.name == "app-version" })?.value == Bundle.main.bundleVersion())
        #expect(queryItems.contains(where: { $0.name == "site-id" }) == false)
        #expect(queryItems.contains(where: { $0.name == "store-id" }) == false)
        #expect(queryItems.contains(where: { $0.name == "store-url" }) == false)
    }

    @Test func scheduleLocalNotificationIfEligible_when_eligible_then_notification_manager_receives_correct_notification() async throws {
        // Given
        let siteSettings = sampleSiteSettings(countryCode: "GB")
        setupMockStores()

        let scheduler = POSNotificationScheduler(
            stores: mockStores,
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

    @Test func scheduleLocalNotificationIfEligible_when_potentialMerchant_already_scheduled_then_currentMerchant_can_still_be_scheduled() async throws {
        // Given
        let siteSettings = sampleSiteSettings(countryCode: "US")
        setupMockStores(isPotentialMerchantScheduled: true, hasPOSBeenOpened: true)

        let scheduler = POSNotificationScheduler(
            stores: mockStores,
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

        // Then
        let notification = try #require(mockPushNotesManager.requestedLocalNotifications.first)
        #expect(notification.scenario == .pointOfSaleCurrentMerchant)
    }

    @Test func scheduleLocalNotificationIfEligible_when_currentMerchant_already_scheduled_then_no_duplicate_scheduled() async throws {
        // Given
        let siteSettings = sampleSiteSettings(countryCode: "US")
        setupMockStores(isCurrentMerchantScheduled: true, hasPOSBeenOpened: true)

        let scheduler = POSNotificationScheduler(
            stores: mockStores,
            siteSettings: siteSettings,
            featureFlagService: mockFeatureFlagService,
            pushNotificationsManager: mockPushNotesManager
        )

        // When
        await scheduler.scheduleLocalNotificationIfEligible(for: .currentMerchant)

        // Then
        #expect(mockPushNotesManager.requestedLocalNotifications.isEmpty)
    }

    @Test func scheduleLocalNotificationIfEligible_when_currentMerchant_but_POS_not_opened_then_no_notification_scheduled() async throws {
        // Given
        let siteSettings = sampleSiteSettings(countryCode: "US")
        setupMockStores(hasPOSBeenOpened: false)

        let scheduler = POSNotificationScheduler(
            stores: mockStores,
            siteSettings: siteSettings,
            featureFlagService: mockFeatureFlagService,
            pushNotificationsManager: mockPushNotesManager
        )

        // When
        await scheduler.scheduleLocalNotificationIfEligible(for: .currentMerchant)

        // Then
        #expect(mockPushNotesManager.requestedLocalNotifications.isEmpty)
    }

    @Test func scheduleLocalNotificationIfEligible_when_currentMerchant_already_scheduled_then_potentialMerchant_cannot_be_scheduled() async throws {
        // Given
        let siteSettings = sampleSiteSettings(countryCode: "US")
        setupMockStores(isCurrentMerchantScheduled: true)

        let scheduler = POSNotificationScheduler(
            stores: mockStores,
            siteSettings: siteSettings,
            featureFlagService: mockFeatureFlagService,
            pushNotificationsManager: mockPushNotesManager
        )

        // When
        await scheduler.scheduleLocalNotificationIfEligible(for: .potentialMerchant)

        // Then - No notification should be scheduled. Prevents backwards conversion from 'current' to 'potential' merchant.
        #expect(mockPushNotesManager.requestedLocalNotifications.isEmpty)
    }

    @Test func scheduleLocalNotificationIfEligible_when_potentialMerchant_already_scheduled_then_does_not_duplicate_notification() async throws {
        // Given
        let siteSettings = sampleSiteSettings(countryCode: "US")
        setupMockStores(isPotentialMerchantScheduled: true)

        let scheduler = POSNotificationScheduler(
            stores: mockStores,
            siteSettings: siteSettings,
            featureFlagService: mockFeatureFlagService,
            pushNotificationsManager: mockPushNotesManager
        )

        // When
        await scheduler.scheduleLocalNotificationIfEligible(for: .potentialMerchant)

        // Then - No duplicate notification should be scheduled
        #expect(mockPushNotesManager.requestedLocalNotifications.isEmpty)
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

    private func taggedSurveyURL(for surveyURL: String) -> URL {
        URL(string: surveyURL)!
            .tagPlatform("ios")
            .tagAppVersion(Bundle.main.bundleVersion())
            .tagSiteInfo(siteID: Self.siteID, storeUUID: Self.storeUUID, storeURL: Self.storeURL)
    }

    private func setupMockStores(stores: MockStoresManager? = nil,
                                  isPotentialMerchantScheduled: Bool = false,
                                  isCurrentMerchantScheduled: Bool = false,
                                  hasPOSBeenOpened: Bool = false) {
        let stores = stores ?? mockStores
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case .getPOSSurveyPotentialMerchantNotificationScheduled(let onCompletion):
                onCompletion(isPotentialMerchantScheduled)
            case .getPOSSurveyCurrentMerchantNotificationScheduled(let onCompletion):
                onCompletion(isCurrentMerchantScheduled)
            case .getHasPOSBeenOpenedAtLeastOnce(let onCompletion):
                onCompletion(hasPOSBeenOpened)
            case .setPOSSurveyPotentialMerchantNotificationScheduled(let onCompletion):
                onCompletion(.success(()))
            case .setPOSSurveyCurrentMerchantNotificationScheduled(let onCompletion):
                onCompletion(.success(()))
            default:
                break
            }
        }
    }
}
