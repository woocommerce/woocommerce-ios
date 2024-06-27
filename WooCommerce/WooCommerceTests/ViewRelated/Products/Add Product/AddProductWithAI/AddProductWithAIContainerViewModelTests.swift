import XCTest
@testable import WooCommerce

final class AddProductWithAIContainerViewModelTests: XCTestCase {
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

// MARK: - `canBeDismissed`

    func test_canBeDismissed_returns_true_if_current_step_is_productName_and_the_name_field_is_empty() {
        // Given
        let viewModel = AddProductWithAIContainerViewModel(siteID: 123, source: .productsTab, onCancel: {}, onCompletion: { _ in })

        // Then
        XCTAssertTrue(viewModel.canBeDismissed)
    }

    func test_canBeDismissed_returns_false_if_current_step_is_productName_and_the_name_field_is_not_empty() {
        // Given
        let viewModel = AddProductWithAIContainerViewModel(siteID: 123,
                                                           source: .productsTab,
                                                           onCancel: {},
                                                           onCompletion: { _ in },
                                                           featureFlagService: MockFeatureFlagService(isProductCreationAIv2M1Enabled: false))

        // When
        viewModel.addProductNameViewModel.productNameContent = "iPhone 15"

        // Then
        XCTAssertFalse(viewModel.canBeDismissed)
    }

    func test_canBeDismissed_returns_false_if_current_step_is_not_product_name() {
        // Given
        let viewModel = AddProductWithAIContainerViewModel(siteID: 123, source: .productsTab, onCancel: {}, onCompletion: { _ in })

        // When
        viewModel.onContinueWithProductName(name: "iPhone 15")

        // Then
        XCTAssertFalse(viewModel.canBeDismissed)

        // When
        viewModel.onProductFeaturesAdded(features: "No lightning jack")

        // Then
        XCTAssertFalse(viewModel.canBeDismissed)
    }

    // MARK: `didGenerateDataFromPackage`

    func test_didGenerateDataFromPackage_sets_values_from_package_flow() {
        // Given
        let expectedName = "Fancy new smart phone"
        let expectedDescription = "Phone, White color"
        let expectedFeatures = expectedDescription

        let viewModel = AddProductWithAIContainerViewModel(siteID: 123,
                                                           source: .productDescriptionAIAnnouncementModal,
                                                           onCancel: { },
                                                           onCompletion: { _ in })

        // When
        viewModel.didGenerateDataFromPackage(.init(name: expectedName,
                                                   description: expectedDescription,
                                                   image: nil))

        // Then
        XCTAssertEqual(viewModel.productName, expectedName)
        XCTAssertEqual(viewModel.productDescription, expectedDescription)
        XCTAssertEqual(viewModel.productFeatures, expectedFeatures)
        XCTAssertEqual(viewModel.addProductNameViewModel.productName, expectedName)
    }

    // MARK: `onProductFeaturesAdded`

    func test_onProductFeaturesAdded_tracks_generate_details_event_with_is_first_attempt_as_true_for_first_time_generation() throws {
        //  Given
        let viewModel = AddProductWithAIContainerViewModel(siteID: 123,
                                                           source: .productDescriptionAIAnnouncementModal,
                                                           analytics: analytics,
                                                           onCancel: { },
                                                           onCompletion: { _ in })
        // When
        viewModel.onProductFeaturesAdded(features: "")

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("product_creation_ai_generate_details_tapped"))

        let eventIndex = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "product_creation_ai_generate_details_tapped"}))
        let eventProperties = analyticsProvider.receivedProperties[eventIndex]
        XCTAssertEqual(eventProperties["is_first_attempt"] as? Bool, true)
    }

    func test_onProductFeaturesAdded_tracks_generate_details_event_with_is_first_attempt_as_false_for_second_time_generation() throws {
        //  Given
        let viewModel = AddProductWithAIContainerViewModel(siteID: 123,
                                                           source: .productDescriptionAIAnnouncementModal,
                                                           analytics: analytics,
                                                           onCancel: { },
                                                           onCompletion: { _ in })
        // When

        // Two generation attempts
        viewModel.onProductFeaturesAdded(features: "")
        viewModel.onProductFeaturesAdded(features: "")

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("product_creation_ai_generate_details_tapped"))

        let eventIndex = try XCTUnwrap(analyticsProvider.receivedEvents.lastIndex(where: { $0 == "product_creation_ai_generate_details_tapped"}))
        let eventProperties = analyticsProvider.receivedProperties[eventIndex]
        XCTAssertEqual(eventProperties["is_first_attempt"] as? Bool, false)
    }
}
