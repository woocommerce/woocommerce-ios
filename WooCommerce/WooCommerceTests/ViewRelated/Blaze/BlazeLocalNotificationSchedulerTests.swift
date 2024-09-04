import XCTest
@testable import WooCommerce
@testable import Yosemite
import protocol Storage.StorageType
import protocol Storage.StorageManagerType

final class BlazeLocalNotificationSchedulerTests: XCTestCase {
    private let siteID: Int64 = 123

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
        storageManager = MockStorageManager()
        let uuid = UUID().uuidString
        defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        pushNotesManager = MockPushNotificationsManager()
    }

    override func tearDown() {
        pushNotesManager = nil
        storageManager = nil
        defaults = nil
        super.tearDown()
    }

    func test_notification_is_scheduled_30_days_after_campaign_ends_when_an_active_non_evergreen_campaign_exists_in_storage() throws {
        // Given
        let campaignStartDate = Date.now.addingDays(1)
        let fakeBlazeCampaign = BlazeCampaignListItem.fake().copy(siteID: siteID,
                                                                  budgetCurrency: "USD",
                                                                  isEvergreen: false,
                                                                  durationDays: 15,
                                                                  startTime: campaignStartDate)
        let sut = DefaultBlazeLocalNotificationScheduler(siteID: siteID,
                                                         storageManager: storageManager,
                                                         userDefaults: defaults,
                                                         pushNotesManager: pushNotesManager)
        sut.scheduleNotifications()

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

    func test_notification_is_scheduled_30_days_after_latest_campaign_ends_when_multiple_active_non_evergreen_campaign_exist_in_storage() throws {
        // Given
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
                                                         storageManager: storageManager,
                                                         userDefaults: defaults,
                                                         pushNotesManager: pushNotesManager)
        sut.scheduleNotifications()

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

    func test_previous_notification_is_cancelled_before_scheduling_new_local_notification() throws {
        // Given
        let campaignStartDate1 = Date.now.addingDays(1)
        let fakeBlazeCampaign1 = BlazeCampaignListItem.fake().copy(siteID: siteID,
                                                                   campaignID: "1",
                                                                   budgetCurrency: "USD",
                                                                   isEvergreen: false,
                                                                   durationDays: 15,
                                                                   startTime: campaignStartDate1)
        let sut = DefaultBlazeLocalNotificationScheduler(siteID: siteID,
                                                         storageManager: storageManager,
                                                         userDefaults: defaults,
                                                         pushNotesManager: pushNotesManager)
        sut.scheduleNotifications()

        // When
        insertCampaigns([fakeBlazeCampaign1])

        waitUntil {
            self.pushNotesManager.requestedLocalNotifications.count == 1
        }

        // Then
        XCTAssertTrue(pushNotesManager.canceledLocalNotificationScenarios.contains([LocalNotification.Scenario.blazeNoCampaignReminder]))
    }

    func test_notification_has_siteID_in_user_info() throws {
        // Given
        let campaignStartDate = Date.now.addingDays(1)
        let fakeBlazeCampaign = BlazeCampaignListItem.fake().copy(siteID: siteID,
                                                                  budgetCurrency: "USD",
                                                                  isEvergreen: false,
                                                                  durationDays: 15,
                                                                  startTime: campaignStartDate)
        let sut = DefaultBlazeLocalNotificationScheduler(siteID: siteID,
                                                         storageManager: storageManager,
                                                         userDefaults: defaults,
                                                         pushNotesManager: pushNotesManager)
        sut.scheduleNotifications()

        // When
        insertCampaigns([fakeBlazeCampaign])

        // Then
        waitUntil {
            self.pushNotesManager.requestedLocalNotifications.isNotEmpty
        }

        let userInfo = try XCTUnwrap(pushNotesManager.requestedLocalNotifications.first?.userInfo)
        let siteIDFromNotification = try XCTUnwrap(userInfo["site_id"] as? Int64)
        XCTAssertEqual(siteID, siteIDFromNotification)
    }

    func test_notification_is_not_scheduled_when_no_active_non_evergreen_campaign_exists_in_storage() throws {
        // Given
        let campaignStartDate = Date.now.addingDays(1)
        let fakeBlazeCampaign = BlazeCampaignListItem.fake().copy(siteID: siteID,
                                                                  uiStatus: BlazeCampaignListItem.Status.rejected.rawValue,
                                                                  budgetCurrency: "USD",
                                                                  isEvergreen: false,
                                                                  durationDays: 15,
                                                                  startTime: campaignStartDate)
        let sut = DefaultBlazeLocalNotificationScheduler(siteID: siteID,
                                                         storageManager: storageManager,
                                                         userDefaults: defaults,
                                                         pushNotesManager: pushNotesManager)
        sut.scheduleNotifications()

        waitForExpectation(timeout: 0.1) { exp in
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

    func test_notification_is_not_scheduled_when_only_evergreen_campaign_exists_in_storage() throws {
        // Given
        let campaignStartDate = Date.now.addingDays(1)
        let fakeBlazeCampaign = BlazeCampaignListItem.fake().copy(siteID: siteID,
                                                                  budgetCurrency: "USD",
                                                                  isEvergreen: true,
                                                                  durationDays: 15,
                                                                  startTime: campaignStartDate)
        let sut = DefaultBlazeLocalNotificationScheduler(siteID: siteID,
                                                         storageManager: storageManager,
                                                         userDefaults: defaults,
                                                         pushNotesManager: pushNotesManager)
        sut.scheduleNotifications()

        waitForExpectation(timeout: 0.1) { exp in
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

    func test_notification_is_not_scheduled_when_notification_already_has_been_interacted_with() throws {
        // Given
        let campaignStartDate = Date.now.addingDays(1)
        defaults[.blazeNoCampaignReminderOpened] = true
        let fakeBlazeCampaign = BlazeCampaignListItem.fake().copy(siteID: siteID,
                                                                  budgetCurrency: "USD",
                                                                  isEvergreen: false,
                                                                  durationDays: 15,
                                                                  startTime: campaignStartDate)
        let sut = DefaultBlazeLocalNotificationScheduler(siteID: siteID,
                                                         storageManager: storageManager,
                                                         userDefaults: defaults,
                                                         pushNotesManager: pushNotesManager)
        sut.scheduleNotifications()

        waitForExpectation(timeout: 0.1) { exp in
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
