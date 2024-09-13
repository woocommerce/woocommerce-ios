import XCTest
@testable import WooCommerce
@testable import Yosemite
import protocol Storage.StorageType
import protocol Storage.StorageManagerType

final class BlazeLocalNotificationSchedulerTests: XCTestCase {
    private let siteID: Int64 = 123
    private var stores: MockStoresManager!

    /// Mock Storage: InMemory
    ///
    private var storageManager: StorageManagerType!

    /// View storage for tests
    private var storage: StorageType {
        storageManager.viewStorage
    }

    private var defaults: UserDefaults!

    private var pushNotesManager: MockPushNotificationsManager!

    override func setUpWithError() throws {
        super.setUp()
        let testURL = "https://example.com"
        let site = Site.fake().copy(siteID: siteID, url: testURL)
        stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: true, defaultSite: site))
        storageManager = MockStorageManager()
        let uuid = UUID().uuidString
        defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        pushNotesManager = MockPushNotificationsManager()
    }

    override func tearDown() {
        pushNotesManager = nil
        storageManager = nil
        defaults = nil
        stores = nil
        super.tearDown()
    }

    // MARK: No campaign reminder

    func test_no_campaign_notification_is_scheduled_30_days_after_campaign_ends_when_an_active_non_evergreen_campaign_exists_in_storage() async throws {
        // Given
        let blazeEligibilityChecker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let campaignStartDate = Date.now.addingDays(1)
        let fakeBlazeCampaign = BlazeCampaignListItem.fake().copy(siteID: siteID,
                                                                  budgetCurrency: "USD",
                                                                  isEvergreen: false,
                                                                  durationDays: 15,
                                                                  startTime: campaignStartDate)
        let sut = DefaultBlazeLocalNotificationScheduler(siteID: siteID,
                                                         stores: stores,
                                                         storageManager: storageManager,
                                                         userDefaults: defaults,
                                                         pushNotesManager: pushNotesManager,
                                                         blazeEligibilityChecker: blazeEligibilityChecker)
        await sut.scheduleNoCampaignReminder()

        // When
        insertCampaigns([fakeBlazeCampaign])

        // Then
        waitUntil {
            self.pushNotesManager.requestedLocalNotifications.isNotEmpty
        }

        let scenario = pushNotesManager.requestedLocalNotifications.first?.scenario
        XCTAssertEqual(scenario, LocalNotification.Scenario.blazeNoCampaignReminder)

        let trigger = try XCTUnwrap(pushNotesManager.triggersForRequestedLocalNotifications.first as? UNCalendarNotificationTrigger)
        let notificationTriggerDate = try XCTUnwrap(trigger.nextTriggerDate())
        let campaignEndTime = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: Int(fakeBlazeCampaign.durationDays), to: campaignStartDate))
        XCTAssertTrue(try XCTUnwrap(Calendar.current.date(byAdding: .day, value: 30, to: campaignEndTime)?.isSameDay(as: notificationTriggerDate)))
    }

    // swiftlint:disable:next line_length
    func test_no_campaign_notification_is_scheduled_30_days_after_latest_campaign_ends_when_multiple_active_non_evergreen_campaign_exist_in_storage() async throws {
        // Given
        let blazeEligibilityChecker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let campaignStartDate1 = Date.now.addingDays(1)
        let campaignStartDate2 = Date.now.addingDays(2)
        let campaignStartDate3 = Date.now.addingDays(3)
        let fakeBlazeCampaign1 = BlazeCampaignListItem.fake().copy(siteID: siteID,
                                                                  budgetCurrency: "USD",
                                                                  isEvergreen: false,
                                                                  durationDays: 15,
                                                                  startTime: campaignStartDate1)
        let fakeBlazeCampaign2 = BlazeCampaignListItem.fake().copy(siteID: siteID,
                                                                  budgetCurrency: "USD",
                                                                  isEvergreen: false,
                                                                  durationDays: 15,
                                                                  startTime: campaignStartDate2)
        let fakeBlazeCampaign3 = BlazeCampaignListItem.fake().copy(siteID: siteID,
                                                                  budgetCurrency: "USD",
                                                                  isEvergreen: false,
                                                                  durationDays: 7,
                                                                  startTime: campaignStartDate3)
        let sut = DefaultBlazeLocalNotificationScheduler(siteID: siteID,
                                                         stores: stores,
                                                         storageManager: storageManager,
                                                         userDefaults: defaults,
                                                         pushNotesManager: pushNotesManager,
                                                         blazeEligibilityChecker: blazeEligibilityChecker)
        await sut.scheduleNoCampaignReminder()

        // When
        insertCampaigns([fakeBlazeCampaign1, fakeBlazeCampaign2, fakeBlazeCampaign3])

        // Then
        waitUntil {
            self.pushNotesManager.requestedLocalNotifications.isNotEmpty
        }

        let scenario = pushNotesManager.requestedLocalNotifications.first?.scenario
        XCTAssertEqual(scenario, LocalNotification.Scenario.blazeNoCampaignReminder)

        let trigger = try XCTUnwrap(pushNotesManager.triggersForRequestedLocalNotifications.first as? UNCalendarNotificationTrigger)
        let notificationTriggerDate = try XCTUnwrap(trigger.nextTriggerDate())
        let campaignEndTime = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: Int(fakeBlazeCampaign2.durationDays), to: campaignStartDate2))
        XCTAssertTrue(try XCTUnwrap(Calendar.current.date(byAdding: .day, value: 30, to: campaignEndTime)?.isSameDay(as: notificationTriggerDate)))
    }

    func test_previous_no_campaign_notification_is_cancelled_before_scheduling_new_no_campaign_notification() async throws {
        // Given
        let blazeEligibilityChecker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let campaignStartDate1 = Date.now.addingDays(1)
        let fakeBlazeCampaign1 = BlazeCampaignListItem.fake().copy(siteID: siteID,
                                                                   campaignID: "1",
                                                                   budgetCurrency: "USD",
                                                                   isEvergreen: false,
                                                                   durationDays: 15,
                                                                   startTime: campaignStartDate1)
        let sut = DefaultBlazeLocalNotificationScheduler(siteID: siteID,
                                                         stores: stores,
                                                         storageManager: storageManager,
                                                         userDefaults: defaults,
                                                         pushNotesManager: pushNotesManager,
                                                         blazeEligibilityChecker: blazeEligibilityChecker)
        await sut.scheduleNoCampaignReminder()

        // When
        insertCampaigns([fakeBlazeCampaign1])

        waitUntil {
            self.pushNotesManager.requestedLocalNotifications.count == 1
        }

        // Then
        XCTAssertTrue(pushNotesManager.canceledLocalNotificationScenarios.contains([LocalNotification.Scenario.blazeNoCampaignReminder]))
    }

    func test_no_campaign_notification_is_scheduled_when_evergreen_campaign_in_storage_is_not_active_and_a_non_evergreen_campaigns_exist() async throws {
        // Given
        let blazeEligibilityChecker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let campaignStartDate = Date.now.addingDays(1)
        let fakeBlazeCampaign1 = BlazeCampaignListItem.fake().copy(siteID: siteID,
                                                                  uiStatus: BlazeCampaignListItem.Status.rejected.rawValue,
                                                                  budgetCurrency: "USD",
                                                                  isEvergreen: true,
                                                                  durationDays: 15,
                                                                  startTime: campaignStartDate)
        let fakeBlazeCampaign2 = BlazeCampaignListItem.fake().copy(siteID: siteID,
                                                                  uiStatus: BlazeCampaignListItem.Status.rejected.rawValue,
                                                                  budgetCurrency: "USD",
                                                                  isEvergreen: false,
                                                                  durationDays: 15,
                                                                  startTime: campaignStartDate)
        let sut = DefaultBlazeLocalNotificationScheduler(siteID: siteID,
                                                         stores: stores,
                                                         storageManager: storageManager,
                                                         userDefaults: defaults,
                                                         pushNotesManager: pushNotesManager,
                                                         blazeEligibilityChecker: blazeEligibilityChecker)
        await sut.scheduleNoCampaignReminder()

        // When
        insertCampaigns([fakeBlazeCampaign1, fakeBlazeCampaign2])

        // Then
        waitUntil {
            self.pushNotesManager.requestedLocalNotifications.isNotEmpty
        }

        let scenario = pushNotesManager.requestedLocalNotifications.first?.scenario
        XCTAssertEqual(scenario, LocalNotification.Scenario.blazeNoCampaignReminder)
    }

    func test_no_campaign_notification_is_not_scheduled_when_only_evergreen_campaign_exists_in_storage() async throws {
        // Given
        let blazeEligibilityChecker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let campaignStartDate = Date.now.addingDays(1)
        let fakeBlazeCampaign = BlazeCampaignListItem.fake().copy(siteID: siteID,
                                                                  budgetCurrency: "USD",
                                                                  isEvergreen: true,
                                                                  durationDays: 15,
                                                                  startTime: campaignStartDate)
        let sut = DefaultBlazeLocalNotificationScheduler(siteID: siteID,
                                                         stores: stores,
                                                         storageManager: storageManager,
                                                         userDefaults: defaults,
                                                         pushNotesManager: pushNotesManager,
                                                         blazeEligibilityChecker: blazeEligibilityChecker)
        await sut.scheduleNoCampaignReminder()

        waitForExpectation(timeout: 0.5) { exp in
            exp.isInverted = true

            // When
            insertCampaigns([fakeBlazeCampaign])

            // Then
            // No local notifications should be requested
            if self.pushNotesManager.requestedLocalNotifications.isNotEmpty {
                exp.fulfill()
            }
        }
    }

    func test_no_campaign_notification_is_not_scheduled_when_notification_already_has_been_interacted_with() async throws {
        // Given
        let blazeEligibilityChecker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let campaignStartDate = Date.now.addingDays(1)
        defaults[.blazeNoCampaignReminderOpened] = true
        let fakeBlazeCampaign = BlazeCampaignListItem.fake().copy(siteID: siteID,
                                                                  budgetCurrency: "USD",
                                                                  isEvergreen: false,
                                                                  durationDays: 15,
                                                                  startTime: campaignStartDate)
        let sut = DefaultBlazeLocalNotificationScheduler(siteID: siteID,
                                                         stores: stores,
                                                         storageManager: storageManager,
                                                         userDefaults: defaults,
                                                         pushNotesManager: pushNotesManager,
                                                         blazeEligibilityChecker: blazeEligibilityChecker)
        await sut.scheduleNoCampaignReminder()

        waitForExpectation(timeout: 0.5) { exp in
            exp.isInverted = true

            // When
            insertCampaigns([fakeBlazeCampaign])

            // Then
            // No local notifications should be requested
            if self.pushNotesManager.requestedLocalNotifications.isNotEmpty {
                exp.fulfill()
            }
        }
    }

    func test_no_campaign_notification_is_not_scheduled_when_store_is_not_eligible_for_blaze() async throws {
        // Given
        let blazeEligibilityChecker = MockBlazeEligibilityChecker(isSiteEligible: false)
        let campaignStartDate = Date.now.addingDays(1)
        let fakeBlazeCampaign = BlazeCampaignListItem.fake().copy(siteID: siteID,
                                                                  budgetCurrency: "USD",
                                                                  isEvergreen: false,
                                                                  durationDays: 15,
                                                                  startTime: campaignStartDate)
        let sut = DefaultBlazeLocalNotificationScheduler(siteID: siteID,
                                                         stores: stores,
                                                         storageManager: storageManager,
                                                         userDefaults: defaults,
                                                         pushNotesManager: pushNotesManager,
                                                         blazeEligibilityChecker: blazeEligibilityChecker)
        await sut.scheduleNoCampaignReminder()

        waitForExpectation(timeout: 0.5) { exp in
            exp.isInverted = true

            // When
            insertCampaigns([fakeBlazeCampaign])

            // Then
            // No local notifications should be requested
            if self.pushNotesManager.requestedLocalNotifications.isNotEmpty {
                exp.fulfill()
            }
        }
    }

    func test_previous_no_campaign_notification_is_cancelled_when_site_is_not_eligible_for_blaze() async throws {
        // Given
        let blazeEligibilityChecker = MockBlazeEligibilityChecker(isSiteEligible: false)
        let sut = DefaultBlazeLocalNotificationScheduler(siteID: siteID,
                                                         stores: stores,
                                                         storageManager: storageManager,
                                                         userDefaults: defaults,
                                                         pushNotesManager: pushNotesManager,
                                                         blazeEligibilityChecker: blazeEligibilityChecker)

        // When
        await sut.scheduleNoCampaignReminder()

        waitUntil {
            self.pushNotesManager.canceledLocalNotificationScenarios.isNotEmpty
        }

        // Then
        XCTAssertTrue(pushNotesManager.canceledLocalNotificationScenarios.contains([LocalNotification.Scenario.blazeNoCampaignReminder]))
    }

    // MARK: Abandoned campaign creation flow

    func test_scheduleAbandonedCreationReminder_schedules_notification_correctly() async throws {
        // Given
        let blazeEligibilityChecker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let sut = DefaultBlazeLocalNotificationScheduler(siteID: siteID,
                                                         stores: stores,
                                                         storageManager: storageManager,
                                                         userDefaults: defaults,
                                                         pushNotesManager: pushNotesManager,
                                                         blazeEligibilityChecker: blazeEligibilityChecker)

        // When
        await sut.scheduleAbandonedCreationReminder()

        // Then
        waitUntil {
            self.pushNotesManager.requestedLocalNotifications.isNotEmpty
        }

        let scenario = try XCTUnwrap(pushNotesManager.requestedLocalNotifications.first?.scenario)
        XCTAssertEqual(scenario, LocalNotification.Scenario.blazeAbandonedCampaignCreationReminder)
    }

    func test_abandoned_creation_notification_is_not_scheduled_when_store_is_not_eligible_for_blaze() async throws {
        // Given
        let blazeEligibilityChecker = MockBlazeEligibilityChecker(isSiteEligible: false)
        let sut = DefaultBlazeLocalNotificationScheduler(siteID: siteID,
                                                         stores: stores,
                                                         storageManager: storageManager,
                                                         userDefaults: defaults,
                                                         pushNotesManager: pushNotesManager,
                                                         blazeEligibilityChecker: blazeEligibilityChecker)

        // When
        await sut.scheduleAbandonedCreationReminder()

        waitForExpectation(timeout: 0.5) { exp in
            exp.isInverted = true

            // Then
            // No local notifications should be requested
            if self.pushNotesManager.requestedLocalNotifications.isNotEmpty {
                exp.fulfill()
            }
        }
    }

    func test_previous_abandoned_creation_notification_is_cancelled_before_scheduling_new_abandoned_creation_notification() async throws {
        // Given
        let blazeEligibilityChecker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let sut = DefaultBlazeLocalNotificationScheduler(siteID: siteID,
                                                         stores: stores,
                                                         storageManager: storageManager,
                                                         userDefaults: defaults,
                                                         pushNotesManager: pushNotesManager,
                                                         blazeEligibilityChecker: blazeEligibilityChecker)
        // When
        await sut.scheduleAbandonedCreationReminder()

        waitUntil {
            self.pushNotesManager.requestedLocalNotifications.count == 1
        }

        // Then
        XCTAssertTrue(pushNotesManager.canceledLocalNotificationScenarios.contains([LocalNotification.Scenario.blazeAbandonedCampaignCreationReminder]))
    }

    func test_abandoned_creation_notification_is_not_scheduled_when_notification_already_has_been_interacted_with() async throws {
        // Given
        let blazeEligibilityChecker = MockBlazeEligibilityChecker(isSiteEligible: true)
        defaults[.blazeAbandonedCampaignCreationReminderOpened] = true

        let sut = DefaultBlazeLocalNotificationScheduler(siteID: siteID,
                                                         stores: stores,
                                                         storageManager: storageManager,
                                                         userDefaults: defaults,
                                                         pushNotesManager: pushNotesManager,
                                                         blazeEligibilityChecker: blazeEligibilityChecker)
        // When
        await sut.scheduleAbandonedCreationReminder()

        waitForExpectation(timeout: 0.5) { exp in
            exp.isInverted = true

            // Then
            // No local notifications should be requested
            if self.pushNotesManager.requestedLocalNotifications.isNotEmpty {
                exp.fulfill()
            }
        }
    }

    // MARK: User response

    func test_it_observes_abandoned_creation_notification_and_updates_user_defaults() async throws {
        // Given
        let blazeEligibilityChecker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let sut = DefaultBlazeLocalNotificationScheduler(siteID: siteID,
                                                   stores: stores,
                                                   storageManager: storageManager,
                                                   userDefaults: defaults,
                                                   pushNotesManager: pushNotesManager,
                                                   blazeEligibilityChecker: blazeEligibilityChecker)
        let response = try XCTUnwrap(MockNotificationResponse(actionIdentifier: "",
                                                              requestIdentifier: LocalNotification.Scenario.blazeAbandonedCampaignCreationReminder.identifier,
                                                              notificationUserInfo: [:]))

        // When
        pushNotesManager.sendLocalNotificationResponse(response)

        // Then
        waitUntil {
            self.defaults[.blazeAbandonedCampaignCreationReminderOpened] == true
        }
    }

    func test_it_observes_no_campaign_notification_and_updates_user_defaults() async throws {
        // Given
        let blazeEligibilityChecker = MockBlazeEligibilityChecker(isSiteEligible: true)
        let sut = DefaultBlazeLocalNotificationScheduler(siteID: siteID,
                                                   stores: stores,
                                                   storageManager: storageManager,
                                                   userDefaults: defaults,
                                                   pushNotesManager: pushNotesManager,
                                                   blazeEligibilityChecker: blazeEligibilityChecker)
        let response = try XCTUnwrap(MockNotificationResponse(actionIdentifier: "",
                                                              requestIdentifier: LocalNotification.Scenario.blazeNoCampaignReminder.identifier,
                                                              notificationUserInfo: [:]))

        // When
        pushNotesManager.sendLocalNotificationResponse(response)

        // Then
        waitUntil {
            self.defaults[.blazeNoCampaignReminderOpened] == true
        }
    }
}

private extension BlazeLocalNotificationSchedulerTests {
    func insertCampaigns(_ readOnlyCampaigns: [BlazeCampaignListItem]) {
        readOnlyCampaigns.forEach { campaign in
            let newCampaign = storage.insertNewObject(ofType: StorageBlazeCampaignListItem.self)
            newCampaign.update(with: campaign)
        }
        storage.saveIfNeeded()
    }
}
