import Combine
import Foundation
import Testing
import Yosemite
import protocol Storage.StorageManagerType
import protocol Storage.StorageType
@testable import WooCommerce
@testable import Networking

class BookingListContainerViewModelTests {

    private let site = Site.fake()
    private let analyticsProvider = MockAnalyticsProvider()
    private lazy var analytics: WooAnalytics = WooAnalytics(analyticsProvider: self.analyticsProvider)
    private var storageManager: StorageManagerType = MockStorageManager()
    private lazy var storage: StorageType = {
        storageManager.viewStorage
    }()

    @MainActor
    @Test func test_event_fire_when_tab_selected() {
        // Given
        let viewModel = givenViewModel()

        // When
        viewModel.setSelectedTab(to: .all)

        // Then
        #expect(analyticsProvider.received(event: "booking_list_tab_selected",
                                         with: ["selected_tab": "all"]))
        #expect(analyticsProvider.received(event: "booking_list_displayed",
                                           with: [
                                            "selected_tab": "all",
                                            "is_default_tab": false,
                                            "is_list_empty": true,
                                            "is_filtered": false
                                           ]))
    }

    @MainActor
    @Test func test_event_fire_when_onAppear() {
        // Given
        let viewModel = givenViewModel()

        // When
        viewModel.onAppear()

        // Then
        #expect(analyticsProvider.received(event: "booking_list_displayed",
                                           with: [
                                            "selected_tab": "today",
                                            "is_default_tab": true,
                                            "is_list_empty": true,
                                            "is_filtered": false
                                           ]))
    }
}

fileprivate extension BookingListContainerViewModelTests {
    func givenViewModel() -> BookingListContainerViewModel {
        return BookingListContainerViewModel(
            siteID: site.siteID,
            stores: MockStoresManager(sessionManager: .testingInstance),
            analytics: analytics
        )
    }
}
