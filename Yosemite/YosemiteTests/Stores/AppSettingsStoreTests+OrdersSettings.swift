import XCTest
@testable import Yosemite
@testable import Storage

final class AppSettingsStoreTests_OrdersSettings: XCTestCase {
    /// Mock Dispatcher!
    ///
    private var dispatcher: Dispatcher!

    /// Mock Storage: InMemory
    ///
    private var storageManager: MockStorageManager!

    /// Mock File Storage: Load data in memory
    ///
    private var fileStorage: MockInMemoryStorage!

    /// Test subject
    ///
    private var subject: AppSettingsStore!

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockStorageManager()
        fileStorage = MockInMemoryStorage()
        subject = AppSettingsStore(dispatcher: dispatcher, storageManager: storageManager, fileStorage: fileStorage)
    }

    override func tearDown() {
        dispatcher = nil
        storageManager = nil
        fileStorage = nil
        subject = nil
        super.tearDown()
    }

    func test_ordersSettings_actions_returns_values_after_being_set() throws {
        // Given
        let siteID: Int64 = 134

        let orderStatuses: [OrderStatusEnum] = [.pending, .completed]
        let startDate = Date().yearStart
        let endDate = Date().yearEnd
        let dateRange = OrderDateRangeFilter(filter: .custom, startDate: startDate, endDate: endDate)
        let orderSettings = StoredOrderSettings.Setting(siteID: siteID,
                                                        orderStatusesFilter: orderStatuses,
                                                        dateRangeFilter: dateRange)

        // When
        let resultBeforeWriteAction: Result<StoredOrderSettings.Setting, Error> = waitFor { promise in

            let initialReadAction = AppSettingsAction.loadOrdersSettings(siteID: siteID) { result in
                promise(result)
            }
            self.subject.onAction(initialReadAction)
        }
        /// Before any write actions, the orders settings should be nil.
        XCTAssertTrue(resultBeforeWriteAction.isFailure)

        let writeAction = AppSettingsAction.upsertOrdersSettings(siteID: siteID, orderStatusesFilter: orderStatuses, dateRangeFilter: dateRange) { error in
            XCTAssertNil(error)
        }
        subject.onAction(writeAction)


        // Then
        let result1: Result<StoredOrderSettings.Setting, Error> = waitFor { promise in
            let readAction =  AppSettingsAction.loadOrdersSettings(siteID: siteID) { result in
                promise(result)
            }
            self.subject.onAction(readAction)
        }

        XCTAssertTrue(result1.isSuccess)
        XCTAssertEqual(try result1.get(), orderSettings)
    }

    func test_ordersSettings_actions_returns_values_after_being_set_with_two_sites() throws {
        // Given
        let siteID1: Int64 = 134
        let siteID2: Int64 = 268

        let orderStatuses: [OrderStatusEnum] = [.pending, .completed]
        let startDate = Date().yearStart
        let endDate = Date().yearEnd
        let dateRange = OrderDateRangeFilter(filter: .custom, startDate: startDate, endDate: endDate)

        let orderStatuses2: [OrderStatusEnum] = [.pending, .cancelled]
        let startDate2 = Date().yearStart
        let endDate2 = Date().yearEnd
        let dateRange2 = OrderDateRangeFilter(filter: .custom, startDate: startDate2, endDate: endDate2)

        let orderSettings1 = StoredOrderSettings.Setting(siteID: siteID1,
                                                        orderStatusesFilter: orderStatuses,
                                                        dateRangeFilter: dateRange)
        let orderSettings2 = StoredOrderSettings.Setting(siteID: siteID2,
                                                        orderStatusesFilter: orderStatuses2,
                                                        dateRangeFilter: dateRange2)

        // When
        let writeAction1 = AppSettingsAction.upsertOrdersSettings(siteID: siteID1, orderStatusesFilter: orderStatuses, dateRangeFilter: dateRange) { error in
            XCTAssertNil(error)
        }
        subject.onAction(writeAction1)

        let writeAction2 = AppSettingsAction.upsertOrdersSettings(siteID: siteID2, orderStatusesFilter: orderStatuses2, dateRangeFilter: dateRange2) { error in
            XCTAssertNil(error)
        }
        subject.onAction(writeAction2)

        // Then
        let result1: Result<StoredOrderSettings.Setting, Error> = waitFor { promise in
            let readAction =  AppSettingsAction.loadOrdersSettings(siteID: siteID1) { result in
                promise(result)
            }
            self.subject.onAction(readAction)
        }
        XCTAssertTrue(result1.isSuccess)
        XCTAssertEqual(try result1.get(), orderSettings1)

        let result2: Result<StoredOrderSettings.Setting, Error> = waitFor { promise in
            let readAction =  AppSettingsAction.loadOrdersSettings(siteID: siteID2) { result in
                promise(result)
            }
            self.subject.onAction(readAction)
        }
        XCTAssertTrue(result2.isSuccess)
        XCTAssertEqual(try result2.get(), orderSettings2)
    }

    func test_reset_OrdersSettings_action() {
        // When
        let action = AppSettingsAction.resetOrdersSettings
        subject.onAction(action)

        // Then
        XCTAssertTrue(fileStorage.deleteIsHit)
    }
}
