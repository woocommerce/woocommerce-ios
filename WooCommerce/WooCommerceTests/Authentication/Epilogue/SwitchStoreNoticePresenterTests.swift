import XCTest
import TestKit

import Yosemite

@testable import WooCommerce

/// Test cases for `SwitchStoreNoticePresenter`.
///
final class SwitchStoreNoticePresenterTests: XCTestCase {

    private var sessionManager: SessionManager!
    private var noticePresenter: MockNoticePresenter!

    override func setUp() {
        super.setUp()

        sessionManager = SessionManager.testingInstance
        noticePresenter = MockNoticePresenter()
    }

    override func tearDown() {
        noticePresenter = nil
        sessionManager = nil

        super.tearDown()
    }

    func test_it_enqueues_a_notice_when_switching_stores() throws {
        // Given
        let site = makeSite()
        sessionManager.defaultSite = site

        let featureFlagService = MockFeatureFlagService(isPushNotificationsForAllStoresOn: true)
        let presenter = SwitchStoreNoticePresenter(sessionManager: sessionManager,
                                                   noticePresenter: noticePresenter,
                                                   featureFlagService: featureFlagService)

        assertEmpty(noticePresenter.queuedNotices)

        // When
        presenter.presentStoreSwitchedNotice(configuration: .switchingStores)

        // Then
        XCTAssertEqual(noticePresenter.queuedNotices.count, 1)

        let notice = try XCTUnwrap(noticePresenter.queuedNotices.first)
        assertThat(notice.title, contains: site.name)
        let expectedTitle = String.localizedStringWithFormat(SwitchStoreNoticePresenter.Localization.titleFormat, site.name)
        XCTAssertEqual(notice.title, expectedTitle)
    }

    func test_it_does_not_enqueue_a_notice_when_not_switching_stores() throws {
        // Given
        let presenter = SwitchStoreNoticePresenter(sessionManager: sessionManager, noticePresenter: noticePresenter)

        // When
        presenter.presentStoreSwitchedNotice(configuration: .login)

        // Then
        assertEmpty(noticePresenter.queuedNotices)
    }

    func test_notice_title_contains_single_store_push_notifications_message_when_switching_stores_with_pushNotificationsForAllStores_disabled() throws {
        // Given
        let site = makeSite()
        sessionManager.defaultSite = site

        let featureFlagService = MockFeatureFlagService(isPushNotificationsForAllStoresOn: false)
        let presenter = SwitchStoreNoticePresenter(sessionManager: sessionManager,
                                                   noticePresenter: noticePresenter,
                                                   featureFlagService: featureFlagService)

        assertEmpty(noticePresenter.queuedNotices)

        // When
        presenter.presentStoreSwitchedNotice(configuration: .switchingStores)

        // Then
        let notice = try XCTUnwrap(noticePresenter.queuedNotices.first)
        assertThat(notice.title, contains: site.name)
        let expectedTitle =
            String.localizedStringWithFormat(SwitchStoreNoticePresenter.Localization.titleFormatWithPushNotificationsForAllStoresDisabled, site.name)
        XCTAssertEqual(notice.title, expectedTitle)
    }
}

// MARK: - Private Utils

private extension SwitchStoreNoticePresenterTests {
    func makeSite() -> Site {
        Site(siteID: 999,
             name: "Fugiat",
             description: "",
             url: "",
             plan: "",
             isWooCommerceActive: true,
             isWordPressStore: true,
             timezone: "",
             gmtOffset: 0)
    }
}
