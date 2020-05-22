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
        let data = NotificationCountPListWrapper(countBySite: [defaultSiteID: [.comment: 2, .storeOrder: 6]])
        try! fileStorage.write(data, to: URL(fileURLWithPath: ""))

        var notificationCount: Int?
        waitForExpectation { expectation in
            let action = NotificationCountAction.incrementNotificationCount(siteID: defaultSiteID, type: .comment, incrementCount: 10) {
                let loadAction = NotificationCountAction.loadNotificationCount(siteID: self.defaultSiteID, type: .comment) { count in
                    notificationCount = count
                    expectation.fulfill()
                }
                self.subject.dispatcher.dispatch(loadAction)
            }
            subject.dispatcher.dispatch(action)
        }

        XCTAssertEqual(notificationCount, 12)
    }

    // MARK: `loadNotificationCount`

    func testLoadingNotificationCountWithoutPreviousDataReturns0() {
        var notificationCount: Int?
        waitForExpectation { expectation in
            let action = NotificationCountAction.loadNotificationCount(siteID: defaultSiteID, type: .comment) { count in
                notificationCount = count
                expectation.fulfill()
            }
            subject.dispatcher.dispatch(action)
        }

        XCTAssertEqual(notificationCount, 0)
    }

    // MARK: `resetNotificationCount`

    func testResettingNotificationCountOfAGivenTypeReturns0() {
        let data = NotificationCountPListWrapper(countBySite: [defaultSiteID: [.comment: 2, .storeOrder: 6]])
        try! fileStorage.write(data, to: URL(fileURLWithPath: ""))

        var notificationCount: Int?
        waitForExpectation { expectation in
            let action = NotificationCountAction.resetNotificationCount(siteID: defaultSiteID, type: .comment) {
                let loadAction = NotificationCountAction.loadNotificationCount(siteID: self.defaultSiteID, type: .comment) { count in
                    notificationCount = count
                    expectation.fulfill()
                }
                self.subject.dispatcher.dispatch(loadAction)
            }
            subject.dispatcher.dispatch(action)
        }

        XCTAssertEqual(notificationCount, 0)
    }

    func testResettingNotificationCountForASiteDoesNotAffectAnotherSite() {
        // Arrange
        let anotherSiteID: Int64 = 999
        let data = NotificationCountPListWrapper(countBySite: [
            defaultSiteID: [.comment: 2, .storeOrder: 6],
            anotherSiteID: [.comment: 3]
        ])
        try! fileStorage.write(data, to: URL(fileURLWithPath: ""))

        // Action
        var notificationCount: Int?
        waitForExpectation { expectation in
            let action = NotificationCountAction.resetNotificationCount(siteID: defaultSiteID, type: .comment) {
                let loadAction = NotificationCountAction.loadNotificationCount(siteID: anotherSiteID, type: .comment) { count in
                    notificationCount = count
                    expectation.fulfill()
                }
                self.subject.dispatcher.dispatch(loadAction)
            }
            subject.dispatcher.dispatch(action)
        }

        // Assert
        XCTAssertEqual(notificationCount, 3)
    }

    // MARK: `resetNotificationCountForAllSites`

    func testResettingNotificationCountForTwoSites() {
        // Arrange
        let anotherSiteID: Int64 = 999
        let data = NotificationCountPListWrapper(countBySite: [
            defaultSiteID: [.comment: 2, .storeOrder: 6],
            anotherSiteID: [.comment: 3]
        ])
        try! fileStorage.write(data, to: URL(fileURLWithPath: ""))

        // Action
        var notificationCountOfDefaultSite: Int?
        var notificationCountOfAnotherSite: Int?
        waitForExpectation { expectation in
            let action = NotificationCountAction.resetNotificationCountForAllSites {
                let loadDefaultSiteCountAction = NotificationCountAction.loadNotificationCount(siteID: self.defaultSiteID, type: nil) { count in
                    notificationCountOfDefaultSite = count

                    if notificationCountOfDefaultSite != nil && notificationCountOfAnotherSite != nil {
                        expectation.fulfill()
                    }
                }
                self.subject.dispatcher.dispatch(loadDefaultSiteCountAction)

                let loadAnotherSiteCountAction = NotificationCountAction.loadNotificationCount(siteID: anotherSiteID, type: nil) { count in
                    notificationCountOfAnotherSite = count

                    if notificationCountOfDefaultSite != nil && notificationCountOfAnotherSite != nil {
                        expectation.fulfill()
                    }
                }
                self.subject.dispatcher.dispatch(loadAnotherSiteCountAction)
            }
            subject.dispatcher.dispatch(action)
        }

        // Assert
        XCTAssertTrue(fileStorage.deleteIsHit)
        XCTAssertEqual(notificationCountOfDefaultSite, 0)
        XCTAssertEqual(notificationCountOfAnotherSite, 0)
    }
}
