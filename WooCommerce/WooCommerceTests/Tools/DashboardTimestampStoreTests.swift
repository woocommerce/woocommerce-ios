import XCTest
@testable import WooCommerce

final class DashboardTimestampStoreTests: XCTestCase {

    func test_timestamps_are_stored_correctly() throws {
        // Given
        let store = try XCTUnwrap(UserDefaults(suiteName: "test-store"))

        // When
        for card in DashboardTimestampStore.Card.allCases {
            for range in DashboardTimestampStore.TimeRange.allCases {
                DashboardTimestampStore.saveTimestamp(.now, for: card, at: range, store: store)
            }
        }

        // Then
        for card in DashboardTimestampStore.Card.allCases {
            for range in DashboardTimestampStore.TimeRange.allCases {
                XCTAssertNotNil(DashboardTimestampStore.loadTimestamp(for: card, at: range, store: store))
            }
        }
    }

    func test_timestamps_are_deleted_correctly() throws {
        // Given
        let store = try XCTUnwrap(UserDefaults(suiteName: "test-store"))
        for card in DashboardTimestampStore.Card.allCases {
            for range in DashboardTimestampStore.TimeRange.allCases {
                DashboardTimestampStore.saveTimestamp(.now, for: card, at: range, store: store)
            }
        }

        // When
        DashboardTimestampStore.resetStore(store: store)

        // Then
        for card in DashboardTimestampStore.Card.allCases {
            for range in DashboardTimestampStore.TimeRange.allCases {
                XCTAssertNil(DashboardTimestampStore.loadTimestamp(for: card, at: range, store: store))
            }
        }
    }
}
