import XCTest
@testable import Yosemite

final class NotificationCountPListWrapperTests: XCTestCase {
    private let defaultSiteID: Int64 = 134

    func testNotificationCountReturns0WithoutDataForTheSite() {
        let wrapper = NotificationCountPListWrapper(countBySite: [:])
        XCTAssertEqual(wrapper.notificationCount(siteID: defaultSiteID, type: nil), 0)
    }

    func testNotificationCountReturns0WithoutDataForTheType() {
        let wrapper = NotificationCountPListWrapper(countBySite: [defaultSiteID: [.comment: 2]])
        XCTAssertEqual(wrapper.notificationCount(siteID: defaultSiteID, type: .storeOrder), 0)
    }

    func testNotificationCountForAType() {
        let wrapper = NotificationCountPListWrapper(countBySite: [defaultSiteID: [.comment: 2]])
        XCTAssertEqual(wrapper.notificationCount(siteID: defaultSiteID, type: .comment), 2)
    }

    func testNotificationCountForAllTypes() {
        let wrapper = NotificationCountPListWrapper(countBySite: [defaultSiteID: [.comment: 2, .storeOrder: 6]])
        XCTAssertEqual(wrapper.notificationCount(siteID: defaultSiteID, type: nil), 8)
    }
}
