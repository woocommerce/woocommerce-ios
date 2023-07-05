import Combine
import XCTest
import Yosemite
@testable import WooCommerce

@MainActor
final class ProductDescriptionGenerationViewModelTests: XCTestCase {
    private var stores: MockStoresManager!
    private var subscriptions: Set<AnyCancellable> = []

    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!

    override func setUp() {
        super.setUp()

        stores = MockStoresManager(sessionManager: .testingInstance)
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
    }

    override func tearDown() {
        stores = nil
        analytics = nil
        analyticsProvider = nil

        super.tearDown()
    }

    // MARK: - `isProductNameEditable`
    func test_isProductNameEditable_returns_true_when_initial_product_name_is_empty() {
        // Given
        let viewModel = ProductDescriptionGenerationViewModel(siteID: 6, name: "", description: "", stores: stores, onApply: { _ in })

        // Then
        XCTAssertTrue(viewModel.isProductNameEditable)
    }

    func test_isProductNameEditable_returns_false_when_initial_product_name_is_not_empty() {
        // Given
        let viewModel = ProductDescriptionGenerationViewModel(siteID: 6, name: "Test", description: "", stores: stores, onApply: { _ in })

        // Then
        XCTAssertFalse(viewModel.isProductNameEditable)
    }

    // MARK: - `suggestedText`

    func test_suggestedText_is_set_after_generateDescription_success() throws {
        // Given
        mockGeneratedDescription(result: .success("Must buy"))

        let viewModel = ProductDescriptionGenerationViewModel(siteID: 6, name: "", description: "", stores: stores, onApply: { _ in })
        XCTAssertNil(viewModel.suggestedText)

        // When
        viewModel.generateDescription()

        // Then
        waitUntil {
            viewModel.suggestedText == "Must buy"
        }
    }

    // MARK: - `errorMessage`

    func test_errorMessage_is_set_after_generateDescription_failure() throws {
        // Given
        mockGeneratedDescription(result: .failure(TestError.generationFailure))

        let viewModel = ProductDescriptionGenerationViewModel(siteID: 6, name: "", description: "", stores: stores, onApply: { _ in })

        // When
        viewModel.generateDescription()

        // Then
        waitUntil {
            viewModel.errorMessage == "Generation error"
        }
    }

    // MARK: - `onApply`

    func test_applyToProductonApply_invokes_onApply_with_generated_description_and_updated_product_name() throws {
        // Given
        mockGeneratedDescription(result: .success("Must buy"))

        var productContent: ProductDescriptionGenerationOutput?
        let viewModel = ProductDescriptionGenerationViewModel(siteID: 6,
                                                              name: "",
                                                              description: "Durable",
                                                              stores: stores,
                                                              onApply: { content in
            productContent = content
        })

        // When
        viewModel.name = "Fun"
        viewModel.generateDescription()
        waitUntil {
            viewModel.isGenerationInProgress == false
        }
        viewModel.applyToProduct()

        // Then
        XCTAssertEqual(productContent, .init(name: "Fun", description: "Must buy"))
    }

    // MARK: - `isGenerationInProgress`

    func test_isGenerationInProgress_becomes_true_when_generating_description() throws {
        // Given
        let viewModel = ProductDescriptionGenerationViewModel(siteID: 6, name: "", description: "", onApply: { _ in })
        XCTAssertFalse(viewModel.isGenerationInProgress)

        // When
        viewModel.generateDescription()

        // Then
        XCTAssertTrue(viewModel.isGenerationInProgress)
    }

    // MARK: - `isGenerationEnabled`

    func test_isGenerationEnabled_is_false_when_product_name_is_empty() throws {
        // Given
        let viewModel = ProductDescriptionGenerationViewModel(siteID: 6, name: "", description: "a product", onApply: { _ in })

        // Then
        XCTAssertFalse(viewModel.isGenerationEnabled)
    }

    func test_isGenerationEnabled_is_false_when_product_description_is_empty() throws {
        // Given
        let viewModel = ProductDescriptionGenerationViewModel(siteID: 6, name: "Woo plate", description: "", onApply: { _ in })

        // Then
        XCTAssertFalse(viewModel.isGenerationEnabled)
    }

    func test_isGenerationEnabled_is_true_when_product_name_and_description_are_not_empty() throws {
        // Given
        let viewModel = ProductDescriptionGenerationViewModel(siteID: 6, name: "Woo", description: "a product", onApply: { _ in })

        // Then
        XCTAssertTrue(viewModel.isGenerationEnabled)
    }

    // MARK: - `shouldShowFeedbackView`
    func test_shouldShowFeedbackView_is_true_after_generating_a_description() {
        // Given
        mockGeneratedDescription(result: .success("Must buy"))

        let viewModel = ProductDescriptionGenerationViewModel(siteID: 6,
                                                              name: "",
                                                              description: "Durable",
                                                              stores: stores,
                                                              onApply: { _ in })
        XCTAssertFalse(viewModel.shouldShowFeedbackView)

        // When
        viewModel.name = "Fun"
        viewModel.generateDescription()
        waitUntil {
            viewModel.isGenerationInProgress == false
        }

        // Then
        XCTAssertTrue(viewModel.shouldShowFeedbackView)
    }

    func test_handleFeedback_sets_shouldShowFeedbackView_to_false() {
        // Given
        mockGeneratedDescription(result: .success("Must buy"))
        let delay: TimeInterval = 0
        let viewModel = ProductDescriptionGenerationViewModel(siteID: 6,
                                                              name: "",
                                                              description: "Durable",
                                                              delayBeforeDismissingFeedbackBanner: delay,
                                                              stores: stores,
                                                              onApply: { _ in })
        XCTAssertFalse(viewModel.shouldShowFeedbackView)

        viewModel.name = "Fun"
        viewModel.generateDescription()
        waitUntil {
            viewModel.isGenerationInProgress == false
        }
        XCTAssertTrue(viewModel.shouldShowFeedbackView)

        // When
        viewModel.handleFeedback(.up)

        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            XCTAssertFalse(viewModel.shouldShowFeedbackView)
        }
    }

    // MARK: - Analytics
    func test_handleFeedback_tracks_feedback_received() throws {
        // Given
        let viewModel = ProductDescriptionGenerationViewModel(siteID: 6,
                                                              name: "",
                                                              description: "Durable",
                                                              stores: stores,
                                                              analytics: analytics,
                                                              onApply: { _ in })

        // When
        viewModel.handleFeedback(.down)

        // Then
        let index = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "product_ai_feedback"}))
        let eventProperties = analyticsProvider.receivedProperties[index]
        XCTAssertEqual(eventProperties["source"] as? String, "product_description")
        XCTAssertEqual(eventProperties["is_useful"] as? Bool, false)
    }
}

private extension ProductDescriptionGenerationViewModelTests {
    func mockGeneratedDescription(result: Result<String, Error>) {
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            guard case let .generateProductDescription(_, _, _, completion) = action else {
                return XCTFail("Unexpected action: \(action)")
            }
            completion(result)
        }
    }
}

private enum TestError: LocalizedError {
    case generationFailure

    var errorDescription: String? {
        switch self {
        case .generationFailure:
            return "Generation error"
        }
    }
}
