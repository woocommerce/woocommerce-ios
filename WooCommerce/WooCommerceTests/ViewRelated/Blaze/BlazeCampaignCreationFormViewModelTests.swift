import Photos
import Combine
import XCTest
import Yosemite
import protocol Storage.StorageManagerType
import protocol Storage.StorageType
@testable import WooCommerce
import struct Networking.BlazeAISuggestion

@MainActor
final class BlazeCampaignCreationFormViewModelTests: XCTestCase {

    private let sampleSiteID: Int64 = 322

    private let sampleProductID: Int64 = 433

    private var sampleProduct: Product {
        .fake().copy(siteID: sampleSiteID,
                     productID: sampleProductID,
                     statusKey: (ProductStatus.published.rawValue),
                     images: [.fake().copy(imageID: 1)])
    }

    private let sampleImage = UIImage.addOutlineImage

    private let sampleAISuggestions = [BlazeAISuggestion(siteName: "First suggested tagline", textSnippet: "First suggested description"),
                                       BlazeAISuggestion(siteName: "Second suggested tagline", textSnippet: "Second suggested description"),
                                       BlazeAISuggestion(siteName: "Third suggested tagline", textSnippet: "Third suggested description")]

    /// Mock Storage: InMemory
    private var storageManager: StorageManagerType!

    /// View storage for tests
    private var storage: StorageType {
        storageManager.viewStorage
    }

    private var stores: MockStoresManager!

    private var imageLoader: MockProductUIImageLoader!

    override func setUp() {
        super.setUp()
        storageManager = MockStorageManager()
        stores = MockStoresManager(sessionManager: .testingInstance)
        imageLoader = MockProductUIImageLoader()
    }

    // MARK: Initial values
    func test_image_is_empty_initially() async throws {
        // Given
        let viewModel = BlazeCampaignCreationFormViewModel(siteID: sampleSiteID,
                                                           productID: sampleProductID,
                                                           onCompletion: {})

        // Then
        XCTAssertNil(viewModel.image)
    }

    func test_tagline_is_empty_initially() async throws {
        // Given
        let viewModel = BlazeCampaignCreationFormViewModel(siteID: sampleSiteID,
                                                           productID: sampleProductID,
                                                           onCompletion: {})

        // Then
        XCTAssertEqual(viewModel.tagline, "")
    }

    func test_description_is_empty_initially() async throws {
        // Given
        let viewModel = BlazeCampaignCreationFormViewModel(siteID: sampleSiteID,
                                                           productID: sampleProductID,
                                                           onCompletion: {})

        // Then
        XCTAssertEqual(viewModel.description, "")
    }

    // MARK: Download product image

    func test_it_reads_product_from_storage_for_displaying_image() async throws {
        // Given
        insertProduct(sampleProduct)
        mockAISuggestionsSuccess(sampleAISuggestions)
        mockDownloadImage(sampleImage)
        let viewModel = BlazeCampaignCreationFormViewModel(siteID: sampleSiteID,
                                                           productID: sampleProductID,
                                                           stores: stores,
                                                           storage: storageManager,
                                                           productImageLoader: imageLoader,
                                                           onCompletion: {})

        // When
        await viewModel.downloadProductImage()

        // Then
        XCTAssertEqual(imageLoader.imageRequestedForProductImage?.imageID, sampleProduct.images.first?.imageID)
        XCTAssertEqual(viewModel.image?.image, sampleImage)
    }

    // MARK: `canEditAd`

    func test_ad_cannot_be_edited_until_suggestions_are_loaded() async throws {
        // Given
        insertProduct(sampleProduct)
        mockAISuggestionsSuccess(sampleAISuggestions)
        mockDownloadImage(sampleImage)

        let viewModel = BlazeCampaignCreationFormViewModel(siteID: sampleSiteID,
                                                           productID: sampleProductID,
                                                           stores: stores,
                                                           storage: storageManager,
                                                           productImageLoader: imageLoader,
                                                           onCompletion: {})

        // Download product and ensure that ad cannot be edited
        await viewModel.downloadProductImage()
        XCTAssertFalse(viewModel.canEditAd)

        // When
        await viewModel.loadAISuggestions()

        // Then
        XCTAssertTrue(viewModel.canEditAd)
    }

    func test_ad_cannot_be_edited_until_image_is_downloaded() async throws {
        // Given
        insertProduct(sampleProduct)
        mockAISuggestionsSuccess(sampleAISuggestions)
        mockDownloadImage(sampleImage)

        let viewModel = BlazeCampaignCreationFormViewModel(siteID: sampleSiteID,
                                                           productID: sampleProductID,
                                                           stores: stores,
                                                           storage: storageManager,
                                                           productImageLoader: imageLoader,
                                                           onCompletion: {})
        // Load suggestions and ensure that ad cannot be edited
        await viewModel.loadAISuggestions()
        XCTAssertFalse(viewModel.canEditAd)

        // When
        await viewModel.downloadProductImage()

        // Then
        XCTAssertTrue(viewModel.canEditAd)
    }

    func test_ad_can_be_edited_if_suggestions_failed_to_load() async throws {
        // Given
        insertProduct(sampleProduct)
        mockDomainSuggestionsFailure(MockError())
        mockDownloadImage(sampleImage)

        let viewModel = BlazeCampaignCreationFormViewModel(siteID: sampleSiteID,
                                                           productID: sampleProductID,
                                                           stores: stores,
                                                           storage: storageManager,
                                                           productImageLoader: imageLoader,
                                                           onCompletion: {})
        await viewModel.downloadProductImage()

        // When
        await viewModel.loadAISuggestions()

        // Then
        XCTAssertTrue(viewModel.canEditAd)
    }

    func test_ad_can_be_edited_when_product_has_no_image() async throws {
        // Given
        insertProduct(.fake().copy(siteID: sampleSiteID,
                                   productID: sampleProductID,
                                   statusKey: (ProductStatus.published.rawValue),
                                   images: [])) // Product has no image
        mockAISuggestionsSuccess(sampleAISuggestions)

        let viewModel = BlazeCampaignCreationFormViewModel(siteID: sampleSiteID,
                                                           productID: sampleProductID,
                                                           stores: stores,
                                                           storage: storageManager,
                                                           productImageLoader: imageLoader,
                                                           onCompletion: {})
        await viewModel.loadAISuggestions()

        // When
        await viewModel.downloadProductImage()

        // Then
        XCTAssertTrue(viewModel.canEditAd)
    }

    // MARK: Load AI suggestions

    func test_loadAISuggestions_sends_correct_product_ID_to_fetch() async throws {
        // Given
        var expectedProductID: Int64?
        stores.whenReceivingAction(ofType: BlazeAction.self) { [weak self] action in
            guard let self = self else { return }
            switch action {
            case let .fetchAISuggestions(_, productID, completion):
                expectedProductID = productID
                completion(.success(sampleAISuggestions))
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }
        let viewModel = BlazeCampaignCreationFormViewModel(siteID: sampleSiteID,
                                                           productID: sampleProductID,
                                                           stores: stores,
                                                           onCompletion: {})

        // When
        await viewModel.loadAISuggestions()

        // Then
        XCTAssertEqual(expectedProductID, sampleProductID)
    }

    func test_loadAISuggestions_sets_tagline_and_description_upon_success() async throws {
        // Given
        mockAISuggestionsSuccess(sampleAISuggestions)
        let viewModel = BlazeCampaignCreationFormViewModel(siteID: sampleSiteID,
                                                           productID: sampleProductID,
                                                           stores: stores,
                                                           onCompletion: {})

        // When
        await viewModel.loadAISuggestions()

        // Then
        let firstSuggestion = try XCTUnwrap(sampleAISuggestions.first)
        XCTAssertEqual(viewModel.tagline, firstSuggestion.siteName)
        XCTAssertEqual(viewModel.description, firstSuggestion.textSnippet)
    }

    func test_loadAISuggestions_sets_error_if_request_fails() async throws {
        // Given
        mockDomainSuggestionsFailure(MockError())
        let viewModel = BlazeCampaignCreationFormViewModel(siteID: sampleSiteID,
                                                           productID: sampleProductID,
                                                           stores: stores,
                                                           onCompletion: {})

        // When
        await viewModel.loadAISuggestions()

        // Then
        XCTAssertEqual(viewModel.error, .failedToLoadAISuggestions)
    }

    func test_loadAISuggestions_sets_error_if_no_suggestions_available() async throws {
        // Given
        mockAISuggestionsSuccess([])
        let viewModel = BlazeCampaignCreationFormViewModel(siteID: sampleSiteID,
                                                           productID: sampleProductID,
                                                           stores: stores,
                                                           onCompletion: {})

        // When
        await viewModel.loadAISuggestions()

        // Then
        XCTAssertEqual(viewModel.error, .failedToLoadAISuggestions)
    }

    // MARK: `canConfirmDetails`

    func test_ad_cannot_be_confirmed_if_image_is_nil() async throws {
        // Given
        insertProduct(.fake().copy(siteID: sampleSiteID,
                                   productID: sampleProductID,
                                   statusKey: (ProductStatus.published.rawValue),
                                   images: [])) // Product has no image
        mockAISuggestionsSuccess(sampleAISuggestions)

        let viewModel = BlazeCampaignCreationFormViewModel(siteID: sampleSiteID,
                                                           productID: sampleProductID,
                                                           stores: stores,
                                                           storage: storageManager,
                                                           productImageLoader: imageLoader,
                                                           onCompletion: {})
        // Load suggestions to set tagline and description
        await viewModel.loadAISuggestions()

        // When
        await viewModel.downloadProductImage()

        // Then
        XCTAssertNil(viewModel.image)
        XCTAssertFalse(viewModel.canConfirmDetails)
    }

    func test_ad_cannot_be_confirmed_if_tagline_is_empty() async throws {
        // Given
        insertProduct(sampleProduct)
        mockAISuggestionsSuccess([BlazeAISuggestion(siteName: "", // Empty tagline
                                                    textSnippet: "Description")])
        mockDownloadImage(sampleImage)

        let viewModel = BlazeCampaignCreationFormViewModel(siteID: sampleSiteID,
                                                           productID: sampleProductID,
                                                           stores: stores,
                                                           storage: storageManager,
                                                           productImageLoader: imageLoader,
                                                           onCompletion: {})
        // Sets non-nil product image
        await viewModel.downloadProductImage()

        // Load suggestion with empty tagline
        await viewModel.loadAISuggestions()

        // Then
        XCTAssertTrue(viewModel.tagline.isEmpty)
        XCTAssertFalse(viewModel.canConfirmDetails)
    }

    func test_ad_cannot_be_confirmed_if_description_is_empty() async throws {
        // Given
        insertProduct(sampleProduct)
        mockAISuggestionsSuccess([BlazeAISuggestion(siteName: "Tagline",
                                                   textSnippet: "")])  // Empty description
        mockDownloadImage(sampleImage)

        let viewModel = BlazeCampaignCreationFormViewModel(siteID: sampleSiteID,
                                                           productID: sampleProductID,
                                                           stores: stores,
                                                           storage: storageManager,
                                                           productImageLoader: imageLoader,
                                                           onCompletion: {})
        // Sets non-nil product image
        await viewModel.downloadProductImage()

        // Load suggestion with empty description
        await viewModel.loadAISuggestions()

        // Then
        XCTAssertTrue(viewModel.description.isEmpty)
        XCTAssertFalse(viewModel.canConfirmDetails)
    }
}

private extension BlazeCampaignCreationFormViewModelTests {
    /// Insert a `Product` into storage.
    /// 
    func insertProduct(_ readOnlyProduct: Product) {
        let product = storage.insertNewObject(ofType: StorageProduct.self)
        product.update(with: readOnlyProduct)

        for readOnlyImage in readOnlyProduct.images {
            let productImage = storage.insertNewObject(ofType: StorageProductImage.self)
            productImage.update(with: readOnlyImage)
            productImage.product = product
        }
        storage.saveIfNeeded()
    }

    final class MockError: Error { }
}

private class MockProductUIImageLoader: ProductUIImageLoader {
    var imageRequestedForProductImage: Yosemite.ProductImage?
    var requestImageStubbedResponse: UIImage?
    func requestImage(productImage: Yosemite.ProductImage, completion: @escaping (UIImage) -> Void) -> Cancellable? {
        imageRequestedForProductImage = productImage
        if let requestImageStubbedResponse {
            completion(requestImageStubbedResponse)
        }
        return nil
    }

    func requestImage(asset: PHAsset, targetSize: CGSize, completion: @escaping (UIImage) -> Void) {
        // no-op
    }

    func requestImage(asset: PHAsset, targetSize: CGSize, skipsDegradedImage: Bool, completion: @escaping (UIImage) -> Void) {
        // no-op
    }
}

private extension BlazeCampaignCreationFormViewModelTests {
    func mockAISuggestionsSuccess(_ suggestions: [BlazeAISuggestion]) {
        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            switch action {
            case let .fetchAISuggestions(_, _, completion):
                completion(.success(suggestions))
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }
    }

    func mockDomainSuggestionsFailure(_ error: Error) {
        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            switch action {
            case let .fetchAISuggestions(_, _, completion):
                completion(.failure(error))
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }
    }

    func mockDownloadImage(_ image: UIImage?) {
        imageLoader.requestImageStubbedResponse = image
    }
}
