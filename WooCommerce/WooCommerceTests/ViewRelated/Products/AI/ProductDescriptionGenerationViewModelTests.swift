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
        mock(generatedDescription: .success("Must buy"))

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
        mock(generatedDescription: .failure(TestError.generationFailure))

        let viewModel = ProductDescriptionGenerationViewModel(siteID: 6, name: "", description: "", stores: stores, onApply: { _ in })

        // When
        viewModel.generateDescription()

        // Then
        waitUntil {
            viewModel.errorMessage == "Generation error"
        }
    }

    func test_errorMessage_is_set_after_identifyLanguage_failure() throws {
        // Given
        mock(generatedDescription: .success("Must buy"),
             identifyLaunguage: .failure(TestError.generationFailure))

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
        mock(generatedDescription: .success("Must buy"))

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
        mock(generatedDescription: .success("Must buy"))

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
        mock(generatedDescription: .success("Must buy"))
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

    // MARK: - Language identification request

    func test_identify_language_request_is_sent_only_during_first_generation_attempt() {
        // Given
        var identifyLanguageRequestCounter = 0
        let viewModel = ProductDescriptionGenerationViewModel(siteID: 6,
                                                              name: "",
                                                              description: "Durable",
                                                              stores: stores,
                                                              onApply: { _ in })

        viewModel.name = "Fun"
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .generateProductDescription(_, _, _, _, completion):
                completion(.success("Must buy"))
            case let .identifyLanguage(_, _, _, completion):
                completion(.success("en"))
                identifyLanguageRequestCounter += 1
            default:
                return XCTFail("Unexpected action: \(action)")
            }
        }

        // When
        viewModel.generateDescription()
        waitUntil {
            viewModel.isGenerationInProgress == false
        }

        // Then
        XCTAssertEqual(identifyLanguageRequestCounter, 1)

        // When
        // Regeneration attempt
        viewModel.generateDescription()
        waitUntil {
            viewModel.isGenerationInProgress == false
        }

        // Then
        XCTAssertEqual(identifyLanguageRequestCounter, 1)
    }

    func test_identify_language_request_is_sent_again_upon_down_vote() {
        // Given
        var identifyLanguageRequestCounter = 0
        let viewModel = ProductDescriptionGenerationViewModel(siteID: 6,
                                                              name: "",
                                                              description: "Durable",
                                                              stores: stores,
                                                              onApply: { _ in })

        viewModel.name = "Fun"
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .generateProductDescription(_, _, _, _, completion):
                completion(.success("Must buy"))
            case let .identifyLanguage(_, _, _, completion):
                completion(.success("en"))
                identifyLanguageRequestCounter += 1
            default:
                return XCTFail("Unexpected action: \(action)")
            }
        }

        // When
        viewModel.generateDescription()
        waitUntil {
            viewModel.isGenerationInProgress == false
        }

        // Then
        XCTAssertEqual(identifyLanguageRequestCounter, 1)

        // When
        viewModel.handleFeedback(.down)

        viewModel.generateDescription()
        waitUntil {
            viewModel.isGenerationInProgress == false
        }

        // Then
        XCTAssertEqual(identifyLanguageRequestCounter, 2)
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
    func mock(generatedDescription: Result<String, Error>,
              identifyLaunguage: Result<String, Error> = .success("en")) {
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .generateProductDescription(_, _, _, _, completion):
                completion(generatedDescription)
            case let .identifyLanguage(_, _, _, completion):
                completion(identifyLaunguage)
            default:
                return XCTFail("Unexpected action: \(action)")
            }
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
