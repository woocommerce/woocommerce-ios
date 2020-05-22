import XCTest
@testable import Yosemite

final class SiteNotificationCountFileContentsTests: XCTestCase {
    private let defaultSiteID: Int64 = 134

    func testNotificationCountReturns0WithoutDataForTheSite() {
        let wrapper = SiteNotificationCountFileContents(countBySite: [:])
        XCTAssertEqual(wrapper.notificationCount(siteID: defaultSiteID, type: nil), 0)
    }

    func testNotificationCountReturns0WithoutDataForTheType() {
        let wrapper = SiteNotificationCountFileContents(countBySite: [defaultSiteID: [.comment: 2]])
        XCTAssertEqual(wrapper.notificationCount(siteID: defaultSiteID, type: .storeOrder), 0)
    }

    func testNotificationCountForAType() {
        let wrapper = SiteNotificationCountFileContents(countBySite: [defaultSiteID: [.comment: 2]])
        XCTAssertEqual(wrapper.notificationCount(siteID: defaultSiteID, type: .comment), 2)
    }

    func testNotificationCountForAllTypes() {
        let wrapper = SiteNotificationCountFileContents(countBySite: [defaultSiteID: [.comment: 2, .storeOrder: 6]])
        XCTAssertEqual(wrapper.notificationCount(siteID: defaultSiteID, type: nil), 8)
    }
}
