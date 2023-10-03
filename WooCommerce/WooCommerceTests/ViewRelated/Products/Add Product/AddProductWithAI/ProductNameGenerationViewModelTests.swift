import XCTest
import Yosemite
@testable import WooCommerce

@MainActor
final class ProductNameGenerationViewModelTests: XCTestCase {

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

    func test_generateProductName_updates_generationInProgress_correctly() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = ProductNameGenerationViewModel(siteID: 123, keywords: "", stores: stores)
        XCTAssertFalse(viewModel.generationInProgress)

        // When
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .generateProductName(_, _, _, completion):
                XCTAssertTrue(viewModel.generationInProgress)
                completion(.success("iPhone 15 Smart Phone"))
            case let .identifyLanguage(_, _, _, completion):
                XCTAssertTrue(viewModel.generationInProgress)
                completion(.success("en"))
            default:
                break
            }
        }
        await viewModel.generateProductName()

        // Then
        XCTAssertFalse(viewModel.generationInProgress)
    }

    func test_errorMessage_is_updated_when_generateProductName_fails() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = ProductNameGenerationViewModel(siteID: 123, keywords: "", stores: stores)
        let expectedError = NSError(domain: "test", code: 503)

        // When
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .generateProductName(_, _, _, completion):
                XCTAssertNil(viewModel.errorMessage)
                completion(.failure(expectedError))
            case let .identifyLanguage(_, _, _, completion):
                XCTAssertNil(viewModel.errorMessage)
                completion(.success("en"))
            default:
                break
            }
        }
        await viewModel.generateProductName()

        // Then
        XCTAssertEqual(viewModel.errorMessage, expectedError.localizedDescription)
    }

    func test_suggestedText_is_updated_when_generateProductName_succeeds() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = ProductNameGenerationViewModel(siteID: 123, keywords: "", stores: stores)
        let expectedText = "iPhone 15 Smart Phone"
        XCTAssertNil(viewModel.suggestedText)

        // When
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .generateProductName(_, _, _, completion):
                completion(.success(expectedText))
            case let .identifyLanguage(_, _, _, completion):
                completion(.success("en"))
            default:
                break
            }
        }
        await viewModel.generateProductName()

        // Then
        XCTAssertEqual(viewModel.suggestedText, expectedText)
    }

    func test_title_and_image_for_generate_button_are_correct_initially() {
        // Given
        let viewModel = ProductNameGenerationViewModel(siteID: 123, keywords: "")

        // Then
        XCTAssertEqual(viewModel.generateButtonTitle, ProductNameGenerationViewModel.Localization.generate)
        XCTAssertEqual(viewModel.generateButtonImage, .sparklesImage)
        XCTAssertFalse(viewModel.hasGeneratedMessage)
    }

    func test_title_and_image_for_generate_button_are_correct_after_generating_name() async throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = ProductNameGenerationViewModel(siteID: 123, keywords: "", stores: stores)

        // When
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .generateProductName(_, _, _, completion):
                completion(.success("iPhone 15 Smart Phone"))
            case let .identifyLanguage(_, _, _, completion):
                completion(.success("en"))
            default:
                break
            }
        }
        await viewModel.generateProductName()

        // Then
        XCTAssertEqual(viewModel.generateButtonTitle, ProductNameGenerationViewModel.Localization.regenerate)
        XCTAssertEqual(viewModel.generateButtonImage, try XCTUnwrap(UIImage(systemName: "arrow.counterclockwise")))
        XCTAssertTrue(viewModel.hasGeneratedMessage)
    }

    func test_generateProductName_tracks_correct_events_upon_success() async throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = ProductNameGenerationViewModel(siteID: 123, keywords: "", stores: stores, analytics: analytics)

        // When
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .generateProductName(_, _, _, completion):
                completion(.success("iPhone 15 Smart Phone"))
            case let .identifyLanguage(_, _, _, completion):
                completion(.success("en"))
            default:
                break
            }
        }
        await viewModel.generateProductName()

        // Then
        XCTAssertEqual(analyticsProvider.receivedEvents, ["product_name_ai_generate_button_tapped",
                                                          "ai_identify_language_success",
                                                          "product_name_ai_generation_success"])
    }

    func test_generateProductName_tracks_correct_events_upon_failure() async throws {
        // Given
        let expectedError = NSError(domain: "test", code: 503)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = ProductNameGenerationViewModel(siteID: 123, keywords: "", stores: stores, analytics: analytics)

        // When
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .generateProductName(_, _, _, completion):
                completion(.failure(expectedError))
            case let .identifyLanguage(_, _, _, completion):
                completion(.success("en"))
            default:
                break
            }
        }
        await viewModel.generateProductName()

        // Then
        XCTAssertEqual(analyticsProvider.receivedEvents, ["product_name_ai_generate_button_tapped",
                                                          "ai_identify_language_success",
                                                          "product_name_ai_generation_failed"])

        let errorEventIndex = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "product_name_ai_generation_failed"}))
        let errorEventProperties = analyticsProvider.receivedProperties[errorEventIndex]
        XCTAssertEqual(errorEventProperties["error_code"] as? String, "503")
        XCTAssertEqual(errorEventProperties["error_domain"] as? String, "test")
    }

    func test_generateProductName_tracks_identified_language() async throws {
        // Given
        let expectedError = NSError(domain: "test", code: 503)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = ProductNameGenerationViewModel(siteID: 123, keywords: "", stores: stores, analytics: analytics)

        // When
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .generateProductName(_, _, _, completion):
                completion(.failure(expectedError))
            case let .identifyLanguage(_, _, _, completion):
                completion(.success("en"))
            default:
                break
            }
        }
        await viewModel.generateProductName()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("ai_identify_language_success"))

        let eventIndex = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "ai_identify_language_success"}))
        let eventProperties = analyticsProvider.receivedProperties[eventIndex]
        XCTAssertEqual(eventProperties["source"] as? String, "product_name")
        XCTAssertEqual(eventProperties["language"] as? String, "en")
    }

    func test_generateProductName_tracks_correct_events_upon_language_identification_failure() async throws {
        // Given
        let expectedError = NSError(domain: "test", code: 503)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = ProductNameGenerationViewModel(siteID: 123, keywords: "", stores: stores, analytics: analytics)

        // When
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .identifyLanguage(_, _, _, completion):
                completion(.failure(expectedError))
            default:
                break
            }
        }
        await viewModel.generateProductName()

        // Then
        XCTAssertEqual(analyticsProvider.receivedEvents, [
            "product_name_ai_generate_button_tapped",
            "ai_identify_language_failed",
            "product_name_ai_generation_failed"
        ])

        let errorEventIndex = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "ai_identify_language_failed"}))
        let errorEventProperties = analyticsProvider.receivedProperties[errorEventIndex]
        XCTAssertEqual(errorEventProperties["error_code"] as? String, "503")
        XCTAssertEqual(errorEventProperties["error_domain"] as? String, "test")
        XCTAssertEqual(errorEventProperties["source"] as? String, "product_name")
    }

    func test_didTapCopy_tracks_copy_event() {
        // Given
        let viewModel = ProductNameGenerationViewModel(siteID: 123, keywords: "", analytics: analytics)

        // When
        viewModel.didTapCopy()

        // Then
        XCTAssertEqual(analyticsProvider.receivedEvents, ["product_name_ai_copy_button_tapped"])
    }

    func test_didTapApply_tracks_apply_event() {
        // Given
        let viewModel = ProductNameGenerationViewModel(siteID: 123, keywords: "", analytics: analytics)

        // When
        viewModel.didTapApply()

        // Then
        XCTAssertEqual(analyticsProvider.receivedEvents, ["product_name_ai_apply_button_tapped"])
    }
}
