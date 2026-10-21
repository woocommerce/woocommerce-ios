import Foundation
import Testing
import Yosemite
import struct NetworkingCore.AnyCodable
import struct NetworkingCore.MetaContainer
import struct NetworkingCore.Note
@testable import WooCommerce

@MainActor
@Suite(.serialized)
struct PaidOrderNoticeSuppressorTests {
    private let sessionManager: SessionManager = .testingInstance
    private var stores: MockStoresManager { MockStoresManager(sessionManager: sessionManager) }
    private let now = Date(timeIntervalSince1970: 1_750_000_000)

    @Test func test_shouldSuppress_when_payment_was_not_recorded_then_returns_false() {
        // Given
        var suppressor = PaidOrderNoticeSuppressor(stores: stores, currentDate: { now })

        // When
        let suppressed = suppressor.shouldSuppress(notification())

        // Then
        #expect(!suppressed)
    }

    @Test func test_shouldSuppress_when_payment_matches_then_returns_true() {
        // Given
        var suppressor = PaidOrderNoticeSuppressor(stores: stores, currentDate: { now })
        suppressor.recordPayment(for: .fake().copy(siteID: 132, orderID: 306))

        // When
        let suppressed = suppressor.shouldSuppress(notification())

        // Then
        #expect(suppressed)
    }

    @Test(arguments: [299.0, 300.0, 301.0])
    func test_shouldSuppress_when_time_passes_then_expires_at_five_minutes(elapsed: TimeInterval) {
        // Given
        var date = now
        var suppressor = PaidOrderNoticeSuppressor(stores: stores, currentDate: { date })
        suppressor.recordPayment(for: .fake().copy(siteID: 132, orderID: 306))

        // When
        date.addTimeInterval(elapsed)
        let suppressed = suppressor.shouldSuppress(notification())

        // Then
        #expect(suppressed == (elapsed < 300))
    }

    @Test(arguments: [(Int64(132), 307), (Int64(133), 306)])
    func test_shouldSuppress_when_order_or_store_differs_then_returns_false(siteID: Int64, orderID: Int) {
        // Given
        var suppressor = PaidOrderNoticeSuppressor(stores: stores, currentDate: { now })
        suppressor.recordPayment(for: .fake().copy(siteID: 132, orderID: 306))

        // When
        let suppressed = suppressor.shouldSuppress(notification(siteID: siteID, orderID: orderID))

        // Then
        #expect(!suppressed)
    }

    @Test func test_shouldSuppress_when_order_metadata_missing_then_returns_false() {
        // Given
        var suppressor = PaidOrderNoticeSuppressor(stores: stores, currentDate: { now })
        suppressor.recordPayment(for: .fake().copy(siteID: 132, orderID: 306))

        // When
        let suppressed = suppressor.shouldSuppress(notification(orderID: nil))

        // Then
        #expect(!suppressed)
    }

    @Test func test_shouldSuppress_when_kind_differs_then_returns_false() {
        // Given
        var suppressor = PaidOrderNoticeSuppressor(stores: stores, currentDate: { now })
        suppressor.recordPayment(for: .fake().copy(siteID: 132, orderID: 306))

        // When
        let suppressed = suppressor.shouldSuppress(notification(kind: .storeStock))

        // Then
        #expect(!suppressed)
    }

    @Test func test_shouldSuppress_when_site_credentials_session_changes_then_matches_store_url() {
        // Given
        sessionManager.setStoreId(WooConstants.placeholderStoreID)
        sessionManager.defaultSite = .fake().copy(siteID: WooConstants.placeholderStoreID, url: "https://first.example")
        var suppressor = PaidOrderNoticeSuppressor(stores: stores, currentDate: { now }, siteForID: { siteID in
            .fake().copy(siteID: siteID, url: "https://first.example")
        })
        suppressor.recordPayment(for: .fake().copy(siteID: WooConstants.placeholderStoreID, orderID: 306))

        // When
        let firstStoreSuppressed = suppressor.shouldSuppress(notification())
        sessionManager.defaultSite = .fake().copy(siteID: WooConstants.placeholderStoreID, url: "https://second.example")
        let secondStoreSuppressed = suppressor.shouldSuppress(notification())

        // Then
        #expect(firstStoreSuppressed)
        #expect(!secondStoreSuppressed)
    }

    @Test func test_shouldSuppress_when_placeholder_session_receives_another_blog_then_returns_false() {
        // Given
        sessionManager.setStoreId(WooConstants.placeholderStoreID)
        sessionManager.defaultSite = .fake().copy(siteID: WooConstants.placeholderStoreID, url: "https://first.example")
        var suppressor = PaidOrderNoticeSuppressor(stores: stores, currentDate: { now })
        suppressor.recordPayment(for: .fake().copy(siteID: WooConstants.placeholderStoreID, orderID: 306))

        // When
        let suppressed = suppressor.shouldSuppress(notification(siteID: 133))

        // Then
        #expect(!suppressed)
    }

    @Test(arguments: ["https://second.example", "https://first.example/other-store", ""])
    func test_shouldSuppress_when_stored_site_url_differs_then_returns_false(siteURL: String) {
        // Given
        sessionManager.setStoreId(WooConstants.placeholderStoreID)
        sessionManager.defaultSite = .fake().copy(siteID: WooConstants.placeholderStoreID, url: "https://first.example")
        var suppressor = PaidOrderNoticeSuppressor(stores: stores, currentDate: { now }, siteForID: { siteID in
            .fake().copy(siteID: siteID, url: siteURL)
        })
        suppressor.recordPayment(for: .fake().copy(siteID: WooConstants.placeholderStoreID, orderID: 306))

        // When
        let suppressed = suppressor.shouldSuppress(notification())

        // Then
        #expect(!suppressed)
    }

    @Test func test_shouldSuppress_when_lookup_returns_another_blog_then_returns_false() {
        // Given
        sessionManager.setStoreId(WooConstants.placeholderStoreID)
        sessionManager.defaultSite = .fake().copy(siteID: WooConstants.placeholderStoreID, url: "https://first.example")
        var suppressor = PaidOrderNoticeSuppressor(stores: stores, currentDate: { now }, siteForID: { _ in
            .fake().copy(siteID: 133, url: "https://first.example")
        })
        suppressor.recordPayment(for: .fake().copy(siteID: WooConstants.placeholderStoreID, orderID: 306))

        // When
        let suppressed = suppressor.shouldSuppress(notification())

        // Then
        #expect(!suppressed)
    }

    @Test func test_shouldSuppress_when_both_store_urls_empty_then_returns_false() {
        // Given
        sessionManager.setStoreId(WooConstants.placeholderStoreID)
        sessionManager.defaultSite = .fake().copy(siteID: WooConstants.placeholderStoreID, url: "")
        var suppressor = PaidOrderNoticeSuppressor(stores: stores, currentDate: { now }, siteForID: { siteID in
            .fake().copy(siteID: siteID, url: "")
        })
        suppressor.recordPayment(for: .fake().copy(siteID: WooConstants.placeholderStoreID, orderID: 306))

        // When
        let suppressed = suppressor.shouldSuppress(notification())

        // Then
        #expect(!suppressed)
    }

    @Test(arguments: [Int64(0), WooConstants.placeholderStoreID])
    func test_shouldSuppress_when_incoming_blog_id_is_not_real_then_returns_false(siteID: Int64) {
        // Given
        sessionManager.setStoreId(WooConstants.placeholderStoreID)
        sessionManager.defaultSite = .fake().copy(siteID: WooConstants.placeholderStoreID, url: "https://first.example")
        var suppressor = PaidOrderNoticeSuppressor(stores: stores, currentDate: { now }, siteForID: { siteID in
            .fake().copy(siteID: siteID, url: "https://first.example")
        })
        suppressor.recordPayment(for: .fake().copy(siteID: WooConstants.placeholderStoreID, orderID: 306))

        // When
        let suppressed = suppressor.shouldSuppress(notification(siteID: siteID))

        // Then
        #expect(!suppressed)
    }

    private func notification(siteID: Int64 = 132, orderID: Int? = 306, kind: Note.Kind = .storeOrder) -> WooCommerce.PushNotification {
        let meta = orderID.map { MetaContainer(payload: ["ids": AnyCodable(["order": $0])]) }
        return WooCommerce.PushNotification(noteID: nil,
                                siteID: siteID,
                                kind: kind,
                                title: "You have a new order!",
                                subtitle: nil,
                                message: nil,
                                note: nil,
                                meta: meta)
    }
}
