import XCTest
import Yosemite
@testable import WooCommerce

@MainActor
final class ProductNameGenerationViewModelTests: XCTestCase {

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
}
