import TestKit
import XCTest
import Yosemite

@testable import WooCommerce

@MainActor
final class AddProductFromImageViewModelTests: XCTestCase {
    private var stores: MockStoresManager!

    override func setUp() {
        super.setUp()
        stores = MockStoresManager(sessionManager: .makeForTesting())
    }

    override func tearDown() {
        stores = nil
        super.tearDown()
    }

    func test_initial_name_is_empty() throws {
        // Given
        let viewModel = AddProductFromImageViewModel(siteID: 6, source: .productsTab, onAddImage: { _ in nil })

        // Then
        XCTAssertEqual(viewModel.name, "")
    }

    func test_initial_description_is_empty() throws {
        // Given
        let viewModel = AddProductFromImageViewModel(siteID: 6, source: .productsTab, onAddImage: { _ in nil })

        // Then
        XCTAssertEqual(viewModel.description, "")
    }

    // MARK: - `addImage`

    func test_imageState_is_reverted_to_empty_when_addImage_returns_nil() {
        // Given
        let viewModel = AddProductFromImageViewModel(siteID: 6, source: .productsTab, onAddImage: { _ in
            nil
        })
        XCTAssertEqual(viewModel.imageState, .empty)

        // When
        viewModel.addImage(from: .siteMediaLibrary)
        XCTAssertEqual(viewModel.imageState, .loading)

        // Then
        waitUntil {
            viewModel.imageState == .empty
        }
    }

    func test_imageState_is_reverted_to_success_when_addImage_returns_image_then_nil() {
        // Given
        let image = MediaPickerImage(image: .init(), source: .media(media: .fake()))
        var imageToReturn: MediaPickerImage? = image
        let viewModel = AddProductFromImageViewModel(siteID: 6, source: .productsTab, onAddImage: { _ in
            imageToReturn
        })
        XCTAssertEqual(viewModel.imageState, .empty)

        // When adding an image returns an image
        viewModel.addImage(from: .siteMediaLibrary)
        XCTAssertEqual(viewModel.imageState, .loading)

        // Then imageState becomes success
        waitUntil {
            viewModel.imageState == .success(image)
        }

        // When adding an image returns nil
        imageToReturn = nil
        viewModel.addImage(from: .siteMediaLibrary)
        XCTAssertEqual(viewModel.imageState, .loading)

        // Then imageState stays success
        waitUntil {
            viewModel.imageState == .success(image)
        }
    }

    func test_imageState_success_generates_details_with_scanned_texts() {
        // Given
        let image = MediaPickerImage(image: .init(), source: .media(media: .fake()))
        let imageTextScanner = MockImageTextScanner(result: .success(["test"]))
        mockGenerateProductDetails(result: .success(.init(name: "Name", description: "Desc", language: "en")))
        let viewModel = AddProductFromImageViewModel(siteID: 6,
                                                     source: .productsTab,
                                                     stores: stores,
                                                     imageTextScanner: imageTextScanner,
                                                     onAddImage: { _ in
            image
        })

        // When
        viewModel.addImage(from: .siteMediaLibrary)
        waitUntil {
            viewModel.imageState == .success(image)
        }

        // Then
        waitUntil {
            viewModel.isGeneratingDetails == false
        }
        XCTAssertEqual(viewModel.name, "Name")
        XCTAssertEqual(viewModel.description, "Desc")
    }

    func test_generatesProductDetails_failure_sets_errorMessage_and_resets_errorMessage_after_regenerating() {
        // Given
        let image = MediaPickerImage(image: .init(), source: .media(media: .fake()))
        let imageTextScanner = MockImageTextScanner(result: .success(["test"]))
        mockGenerateProductDetails(result: .failure(SampleError.first))
        let viewModel = AddProductFromImageViewModel(siteID: 6,
                                                     stores: stores,
                                                     imageTextScanner: imageTextScanner,
                                                     onAddImage: { _ in
            image
        })

        // When
        viewModel.addImage(from: .siteMediaLibrary)
        waitUntil {
            viewModel.imageState == .success(image)
        }

        // Then
        waitUntil {
            viewModel.isGeneratingDetails == false
        }
        XCTAssertNotNil(viewModel.errorMessage)

        // When regenerating product details with success
        mockGenerateProductDetails(result: .success(.init(name: "", description: "", language: "")))
        viewModel.generateProductDetails()

        // Then `errorMessage` is reset
        waitUntil {
            viewModel.errorMessage == nil
        }
    }

    func test_generateProductDetails_without_scanned_text_does_not_dispatch_product_action() {
        // Given
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            // Then
            XCTFail("Unexpected action: \(action)")
        }
        let viewModel = AddProductFromImageViewModel(siteID: 6,
                                                     source: .productsTab,
                                                     stores: stores,
                                                     onAddImage: { _ in nil })

        // When
        viewModel.generateProductDetails()
    }

    func test_generateProductDetails_filters_empty_scanned_texts() {
        // Given
        let image = MediaPickerImage(image: .init(), source: .media(media: .fake()))
        let imageTextScanner = MockImageTextScanner(result: .success(["", "Product", ""]))
        let viewModel = AddProductFromImageViewModel(siteID: 6,
                                                     source: .productsTab,
                                                     stores: stores,
                                                     imageTextScanner: imageTextScanner,
                                                     onAddImage: { _ in
            image
        })

        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            guard case let .generateProductDetails(_, scannedTexts, _) = action else {
                return XCTFail("Unexpected action: \(action)")
            }
            // Then
            XCTAssertEqual(scannedTexts, ["Product"])
        }

        // When
        viewModel.addImage(from: .siteMediaLibrary)
        waitUntil {
            viewModel.imageState == .success(image)
        }
    }
}

private extension AddProductFromImageViewModelTests {
    func mockGenerateProductDetails(result: Result<ProductDetailsFromScannedTexts, Error>) {
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            guard case let .generateProductDetails(_, _, completion) = action else {
                return XCTFail("Unexpected action: \(action)")
            }
            completion(result)
        }
    }
}
