import XCTest
import TestKit

import Yosemite

@testable import WooCommerce

/// Test cases for `SwitchStoreNoticePresenter`.
///
final class SwitchStoreNoticePresenterTests: XCTestCase {

    private var sessionManager: SessionManager!
    private var stores: StoresManager!
    private var noticePresenter: MockNoticePresenter!

    override func setUp() {
        super.setUp()

        sessionManager = SessionManager.testingInstance
        stores = MockStoresManager(sessionManager: sessionManager)
        noticePresenter = MockNoticePresenter()
    }

    override func tearDown() {
        noticePresenter = nil
        stores = nil
        sessionManager = nil

        super.tearDown()
    }

    func test_it_does_not_enqueue_a_notice_when_switching_stores_without_site() throws {
        // Given
        let siteID = Int64(122)
        sessionManager.defaultSite = nil

        let presenter = SwitchStoreNoticePresenter(siteID: siteID,
                                                   noticePresenter: noticePresenter)

        assertEmpty(noticePresenter.queuedNotices)

        // When
        presenter.presentStoreSwitchedNoticeWhenSiteIsAvailable(configuration: .switchingStores)

        // Then
        assertEmpty(noticePresenter.queuedNotices)
    }

    func test_it_enqueues_a_notice_when_switching_stores_and_site_is_already_available() throws {
        // Given
        let siteID = Int64(122)
        let siteName = "Surprise store"
        let site = Site.fake().copy(siteID: siteID, name: siteName)
        sessionManager.defaultSite = site

        let presenter = SwitchStoreNoticePresenter(siteID: siteID,
                                                   stores: stores,
                                                   noticePresenter: noticePresenter)

        assertEmpty(noticePresenter.queuedNotices)

        // When
        presenter.presentStoreSwitchedNoticeWhenSiteIsAvailable(configuration: .switchingStores)

        // Then
        XCTAssertEqual(noticePresenter.queuedNotices.count, 1)

        let notice = try XCTUnwrap(noticePresenter.queuedNotices.first)
        assertThat(notice.title, contains: siteName)
        let expectedTitle = String.localizedStringWithFormat(SwitchStoreNoticePresenter.Localization.titleFormat, site.name)
        XCTAssertEqual(notice.title, expectedTitle)
    }

    func test_it_enqueues_a_notice_when_switching_stores_after_site_becomes_available() throws {
        // Given
        let siteID = Int64(122)
        let siteName = "Surprise store"
        let site = Site.fake().copy(siteID: siteID, name: siteName)

        let presenter = SwitchStoreNoticePresenter(siteID: siteID,
                                                   stores: stores,
                                                   noticePresenter: noticePresenter)

        assertEmpty(noticePresenter.queuedNotices)

        // When
        presenter.presentStoreSwitchedNoticeWhenSiteIsAvailable(configuration: .switchingStores)
        assertEmpty(noticePresenter.queuedNotices)
        sessionManager.defaultSite = site

        // Then
        XCTAssertEqual(noticePresenter.queuedNotices.count, 1)

        let notice = try XCTUnwrap(noticePresenter.queuedNotices.first)
        assertThat(notice.title, contains: siteName)
        let expectedTitle = String.localizedStringWithFormat(SwitchStoreNoticePresenter.Localization.titleFormat, site.name)
        XCTAssertEqual(notice.title, expectedTitle)
    }

    func test_it_does_not_enqueue_a_notice_when_not_switching_stores() throws {
        // Given
        let siteID = Int64(122)
        let site = Site.fake().copy(siteID: siteID)
        sessionManager.defaultSite = site
        let presenter = SwitchStoreNoticePresenter(siteID: siteID, noticePresenter: noticePresenter)

        // When
        presenter.presentStoreSwitchedNoticeWhenSiteIsAvailable(configuration: .login)

        // Then
        assertEmpty(noticePresenter.queuedNotices)
    }
}
