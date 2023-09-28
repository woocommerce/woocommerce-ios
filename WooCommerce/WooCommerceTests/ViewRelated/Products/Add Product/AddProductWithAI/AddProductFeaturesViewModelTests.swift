import XCTest
@testable import WooCommerce

final class AddProductFeaturesViewModelTests: XCTestCase {
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

    func test_productFeatures_is_updated_with_initial_features() {
        // Given
        let expectedFeatures = "Fancy new smart phone"
        let viewModel = AddProductFeaturesViewModel(siteID: 123,
                                                    isFirstAttemptGeneratingDetails: .constant(true),
                                                    productName: "iPhone 15",
                                                    productFeatures: expectedFeatures,
                                                    onCompletion: { _ in })

        // Then
        XCTAssertEqual(viewModel.productFeatures, expectedFeatures)
    }

    func test_proceedToPreview_triggers_onCompletion() {
        // Given
        var triggeredFeatures: String?
        let expectedFeatures = "Fancy new smart phone"
        let viewModel = AddProductFeaturesViewModel(siteID: 123,
                                                    isFirstAttemptGeneratingDetails: .constant(true),
                                                    productName: "iPhone 15",
                                                    onCompletion: { triggeredFeatures = $0 })

        // When
        viewModel.productFeatures = expectedFeatures
        viewModel.proceedToPreview()

        // Then
        XCTAssertEqual(triggeredFeatures, expectedFeatures)
    }

    // MARK: Analytics

    func test_proceedToPreview_tracks_generate_details_event_with_is_first_attempt_as_true_for_first_time_generation() throws {
        //  Given
        let viewModel = AddProductFeaturesViewModel(siteID: 123,
                                                    isFirstAttemptGeneratingDetails: .constant(true),
                                                    productName: "iPhone 15",
                                                    analytics: analytics,
                                                    onCompletion: { _ in })
        // When
        viewModel.proceedToPreview()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("product_creation_ai_generate_details_tapped"))

        let eventIndex = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "product_creation_ai_generate_details_tapped"}))
        let eventProperties = analyticsProvider.receivedProperties[eventIndex]
        XCTAssertEqual(eventProperties["is_first_attempt"] as? Bool, true)
    }

    func test_proceedToPreview_tracks_generate_details_event_with_is_first_attempt_as_false_for_second_time_generation() throws {
        //  Given
        let viewModel = AddProductFeaturesViewModel(siteID: 123,
                                                    isFirstAttemptGeneratingDetails: .constant(false),
                                                    productName: "iPhone 15",
                                                    analytics: analytics,
                                                    onCompletion: { _ in })
        // When

        // Two generation attempts
        viewModel.proceedToPreview()
        viewModel.proceedToPreview()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("product_creation_ai_generate_details_tapped"))

        let eventIndex = try XCTUnwrap(analyticsProvider.receivedEvents.lastIndex(where: { $0 == "product_creation_ai_generate_details_tapped"}))
        let eventProperties = analyticsProvider.receivedProperties[eventIndex]
        XCTAssertEqual(eventProperties["is_first_attempt"] as? Bool, false)
    }
}
