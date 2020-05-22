import XCTest

@testable import Storage
@testable import Yosemite

final class NotificationCountStoreTests: XCTestCase {
    /// Mockup Dispatcher!
    ///
    private var dispatcher: Dispatcher!

    /// Mockup Storage: InMemory
    ///
    private var storageManager: MockupStorageManager!

    /// Mockup File Storage: Load data in memory
    ///
    private var fileStorage: MockInMemoryStorage!

    /// Test subject
    ///
    private var subject: NotificationCountStore!

    private let defaultSiteID: Int64 = 134

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockupStorageManager()
        fileStorage = MockInMemoryStorage()
        subject = NotificationCountStore(dispatcher: dispatcher, storageManager: storageManager, fileStorage: fileStorage)
    }

    override func tearDown() {
        dispatcher = nil
        storageManager = nil
        fileStorage = nil
        subject = nil
        super.tearDown()
    }

    // MARK: `incrementNotificationCount`

    func testIncrementingAndLoadingNotificationCountReturnsTheCorrectCount() {
        let data = SiteNotificationCountFileContents(countBySite: [defaultSiteID: [.comment: 2, .storeOrder: 6]])
        try! fileStorage.write(data, to: URL(fileURLWithPath: ""))

        var notificationCount: Int?
        waitForExpectation { expectation in
            let action = NotificationCountAction.increment(siteID: defaultSiteID, type: .comment, incrementCount: 10) {
                let loadAction = NotificationCountAction.load(siteID: self.defaultSiteID, type: .kind(.comment)) { count in
                    notificationCount = count
                    expectation.fulfill()
                }
                self.subject.onAction(loadAction)
            }
            subject.onAction(action)
        }

        XCTAssertEqual(notificationCount, 12)
    }

    // MARK: `loadNotificationCount`

    func testLoadingNotificationCountWithoutPreviousDataReturns0() {
        var notificationCount: Int?
        waitForExpectation { expectation in
            let action = NotificationCountAction.load(siteID: defaultSiteID, type: .kind(.comment)) { count in
                notificationCount = count
                expectation.fulfill()
            }
            subject.onAction(action)
        }

        XCTAssertEqual(notificationCount, 0)
    }

    // MARK: `resetNotificationCount`

    func testResettingNotificationCountOfAGivenTypeReturns0() {
        let data = SiteNotificationCountFileContents(countBySite: [defaultSiteID: [.comment: 2, .storeOrder: 6]])
        try! fileStorage.write(data, to: URL(fileURLWithPath: ""))

        var notificationCount: Int?
        waitForExpectation { expectation in
            let action = NotificationCountAction.reset(siteID: defaultSiteID, type: .comment) {
                let loadAction = NotificationCountAction.load(siteID: self.defaultSiteID, type: .kind(.comment)) { count in
                    notificationCount = count
                    expectation.fulfill()
                }
                self.subject.onAction(loadAction)
            }
            subject.onAction(action)
        }

        XCTAssertEqual(notificationCount, 0)
    }

    func testResettingNotificationCountForASiteDoesNotAffectAnotherSite() {
        // Arrange
        let anotherSiteID: Int64 = 999
        let data = SiteNotificationCountFileContents(countBySite: [
            defaultSiteID: [.comment: 2, .storeOrder: 6],
            anotherSiteID: [.comment: 3]
        ])
        try! fileStorage.write(data, to: URL(fileURLWithPath: ""))

        // Action
        var notificationCount: Int?
        waitForExpectation { expectation in
            let action = NotificationCountAction.reset(siteID: defaultSiteID, type: .comment) {
                let loadAction = NotificationCountAction.load(siteID: anotherSiteID, type: .kind(.comment)) { count in
                    notificationCount = count
                    expectation.fulfill()
                }
                self.subject.onAction(loadAction)
            }
            subject.onAction(action)
        }

        // Assert
        XCTAssertEqual(notificationCount, 3)
    }

    // MARK: `resetNotificationCountForAllSites`

    func testResettingNotificationCountForTwoSites() {
        // Arrange
        let anotherSiteID: Int64 = 999
        let data = SiteNotificationCountFileContents(countBySite: [
            defaultSiteID: [.comment: 2, .storeOrder: 6],
            anotherSiteID: [.comment: 3]
        ])
        try! fileStorage.write(data, to: URL(fileURLWithPath: ""))

        // Action
        var notificationCountOfDefaultSite: Int?
        var notificationCountOfAnotherSite: Int?
        waitForExpectation(count: 2) { expectation in
            let action = NotificationCountAction.resetForAllSites {
                let loadDefaultSiteCountAction = NotificationCountAction.load(siteID: self.defaultSiteID, type: .allKinds) { count in
                    notificationCountOfDefaultSite = count

                    expectation.fulfill()
                }
                self.subject.onAction(loadDefaultSiteCountAction)

                let loadAnotherSiteCountAction = NotificationCountAction.load(siteID: anotherSiteID, type: .allKinds) { count in
                    notificationCountOfAnotherSite = count

                    expectation.fulfill()
                }
                self.subject.onAction(loadAnotherSiteCountAction)
            }
            subject.onAction(action)
        }

        // Assert
        XCTAssertTrue(fileStorage.deleteIsHit)
        XCTAssertEqual(notificationCountOfDefaultSite, 0)
        XCTAssertEqual(notificationCountOfAnotherSite, 0)
    }
}
