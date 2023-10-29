import XCTest
import Yosemite
@testable import WooCommerce

final class AddProductNameWithAIViewModelTests: XCTestCase {

    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!

    override func setUp() {
        super.setUp()

        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
    }

    override func tearDown() {
        analytics = nil
        analyticsProvider = nil
        super.tearDown()
    }

    func test_didTapSuggestName_tracks_entry_point_event_for_product_name_ai_with_correct_empty_input() throws {
        //  Given
        let viewModel = AddProductNameWithAIViewModel(siteID: 123, analytics: analytics)

        // When
        viewModel.didTapSuggestName()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("product_name_ai_entry_point_tapped"))

        let eventIndex = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "product_name_ai_entry_point_tapped"}))
        let eventProperties = analyticsProvider.receivedProperties[eventIndex]
        XCTAssertEqual(eventProperties["has_input_name"] as? Bool, false)
        XCTAssertEqual(eventProperties["source"] as? String, "product_creation_ai")
    }

    func test_didTapSuggestName_tracks_entry_point_event_for_product_name_ai_with_correct_non_empty_input() throws {
        //  Given
        let viewModel = AddProductNameWithAIViewModel(siteID: 123, analytics: analytics)

        // When
        viewModel.productNameContent = "iPhone 15"
        viewModel.didTapSuggestName()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("product_name_ai_entry_point_tapped"))

        let eventIndex = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "product_name_ai_entry_point_tapped"}))
        let eventProperties = analyticsProvider.receivedProperties[eventIndex]
        XCTAssertEqual(eventProperties["has_input_name"] as? Bool, true)
        XCTAssertEqual(eventProperties["source"] as? String, "product_creation_ai")
    }

    func test_didTapContinue_tracks_continue_tapped_event() throws {
        //  Given
        let viewModel = AddProductNameWithAIViewModel(siteID: 123, analytics: analytics)

        // When
        viewModel.didTapContinue()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("product_creation_ai_product_name_continue_button_tapped"))
    }
}
