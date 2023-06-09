import XCTest
@testable import WooCommerce
@testable import Yosemite

@MainActor
final class ProductSharingMessageGenerationViewModelTests: XCTestCase {

    func test_viewTitle_is_correct() {
        // Given
        let viewModel = ProductSharingMessageGenerationViewModel(siteID: 123,
                                                                 url: "https://example.com",
                                                                 productName: "Test",
                                                                 productDescription: "Test description")
        let expectedTitle = String.localizedStringWithFormat(ProductSharingMessageGenerationViewModel.Localization.title, "Test")

        // Then
        assertEqual(expectedTitle, viewModel.viewTitle)
    }

    func test_generateShareMessage_updates_generationInProgress_correctly() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = ProductSharingMessageGenerationViewModel(siteID: 123,
                                                                 url: "https://example.com",
                                                                 productName: "Test",
                                                                 productDescription: "Test description")
        XCTAssertFalse(viewModel.generationInProgress)
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .generateProductSharingMessage(_, _, _, _, _, completion):
                XCTAssertTrue(viewModel.generationInProgress)
                completion(.success("Check this out!"))
            default:
                return
            }
        }

        // When
        await viewModel.generateShareMessage()

        // Then
        XCTAssertFalse(viewModel.generationInProgress)
    }

    func test_generateShareMessage_updates_messageContent_upon_success() async {
        // Given
        let expectedString = "Check out this product!"
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = ProductSharingMessageGenerationViewModel(siteID: 123,
                                                                 url: "https://example.com",
                                                                 productName: "Test",
                                                                 productDescription: "Test description",
                                                                 stores: stores)
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .generateProductSharingMessage(_, _, _, _, _, completion):
                completion(.success(expectedString))
            default:
                return
            }
        }
        assertEqual("", viewModel.messageContent)

        // When
        await viewModel.generateShareMessage()

        // Then
        assertEqual(expectedString, viewModel.messageContent)
    }

    func test_generateShareMessage_updates_errorMessage_on_failure() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = ProductSharingMessageGenerationViewModel(siteID: 123,
                                                                 url: "https://example.com",
                                                                 productName: "Test",
                                                                 productDescription: "Test description",
                                                                 stores: stores)
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .generateProductSharingMessage(_, _, _, _, _, completion):
                completion(.failure(NSError(domain: "Test", code: 500)))
            default:
                return
            }
        }
        XCTAssertNil(viewModel.errorMessage)

        // When
        await viewModel.generateShareMessage()

        // Then
        assertEqual(ProductSharingMessageGenerationViewModel.Localization.errorMessage, viewModel.errorMessage)
    }
}
