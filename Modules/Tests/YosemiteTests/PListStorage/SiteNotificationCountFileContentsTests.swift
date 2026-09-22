import XCTest
@testable import Yosemite

final class SiteNotificationCountFileContentsTests: XCTestCase {
    private let defaultSiteID: Int64 = 134

    // MARK: `notificationCount`

    @MainActor
    func testNotificationCountReturns0WithoutDataForTheSite() {
        let contents = SiteNotificationCountFileContents(countBySite: [:])
        XCTAssertEqual(contents.notificationCount(siteID: defaultSiteID, type: .allKinds), 0)
    }

    @MainActor
    func testNotificationCountReturns0WithoutDataForTheType() {
        let contents = SiteNotificationCountFileContents(countBySite: [defaultSiteID: [.comment: 2]])
        XCTAssertEqual(contents.notificationCount(siteID: defaultSiteID, type: .kind(.storeOrder)), 0)
    }

    @MainActor
    func testNotificationCountForAType() {
        let contents = SiteNotificationCountFileContents(countBySite: [defaultSiteID: [.comment: 2]])
        XCTAssertEqual(contents.notificationCount(siteID: defaultSiteID, type: .kind(.comment)), 2)
    }

    @MainActor
    func testNotificationCountForAllTypes() {
        let contents = SiteNotificationCountFileContents(countBySite: [defaultSiteID: [.comment: 2, .storeOrder: 6]])
        XCTAssertEqual(contents.notificationCount(siteID: defaultSiteID, type: .allKinds), 8)
    }

    // MARK: `incrementing`

    @MainActor
    func testIncrementingCommentType() {
        let contents = SiteNotificationCountFileContents(countBySite: [defaultSiteID: [.comment: 2, .storeOrder: 6]])
        let incrementedContents = contents.incrementing(siteID: defaultSiteID, type: .comment, incrementCount: 5)
        XCTAssertEqual(incrementedContents.notificationCount(siteID: defaultSiteID, type: .kind(.comment)), 7)
        XCTAssertEqual(incrementedContents.notificationCount(siteID: defaultSiteID, type: .kind(.storeOrder)), 6)
        XCTAssertEqual(incrementedContents.notificationCount(siteID: defaultSiteID, type: .allKinds), 13)
    }

    @MainActor
    func testIncrementingForOneSiteDoesNotAffectAnotherSite() {
        let contents = SiteNotificationCountFileContents(countBySite: [defaultSiteID: [.comment: 2, .storeOrder: 6]])
        let incrementedContents = contents.incrementing(siteID: 777, type: .comment, incrementCount: 5)
        XCTAssertEqual(incrementedContents.notificationCount(siteID: defaultSiteID, type: .kind(.comment)), 2)
        XCTAssertEqual(incrementedContents.notificationCount(siteID: defaultSiteID, type: .kind(.storeOrder)), 6)
        XCTAssertEqual(incrementedContents.notificationCount(siteID: defaultSiteID, type: .allKinds), 8)
    }

    // MARK: `resetting`

    @MainActor
    func testResettingCommentType() {
        let contents = SiteNotificationCountFileContents(countBySite: [defaultSiteID: [.comment: 2, .storeOrder: 6]])
        let incrementedContents = contents.resetting(siteID: defaultSiteID, type: .comment)
        XCTAssertEqual(incrementedContents.notificationCount(siteID: defaultSiteID, type: .kind(.comment)), 0)
        XCTAssertEqual(incrementedContents.notificationCount(siteID: defaultSiteID, type: .kind(.storeOrder)), 6)
        XCTAssertEqual(incrementedContents.notificationCount(siteID: defaultSiteID, type: .allKinds), 6)
    }

    @MainActor
    func testResettingForOneSiteDoesNotAffectAnotherSite() {
        let contents = SiteNotificationCountFileContents(countBySite: [defaultSiteID: [.comment: 2, .storeOrder: 6]])
        let incrementedContents = contents.resetting(siteID: 777, type: .comment)
        XCTAssertEqual(incrementedContents.notificationCount(siteID: defaultSiteID, type: .kind(.comment)), 2)
        XCTAssertEqual(incrementedContents.notificationCount(siteID: defaultSiteID, type: .kind(.storeOrder)), 6)
        XCTAssertEqual(incrementedContents.notificationCount(siteID: defaultSiteID, type: .allKinds), 8)
    }
}
