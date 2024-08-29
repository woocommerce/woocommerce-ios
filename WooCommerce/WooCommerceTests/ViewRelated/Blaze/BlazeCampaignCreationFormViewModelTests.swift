import Photos
import Combine
import XCTest
import Yosemite
import protocol Storage.StorageManagerType
import protocol Storage.StorageType
@testable import WooCommerce
import struct Networking.BlazeAISuggestion

final class BlazeCampaignCreationFormViewModelTests: XCTestCase {

    private let sampleSiteID: Int64 = 322
    private let sampleSiteAddress = "https://example.com"
    private let sampleProductID: Int64 = 433

    private var sampleProduct: Product {
        .fake().copy(siteID: sampleSiteID,
                     productID: sampleProductID,
                     permalink: "Sample product url",
                     statusKey: (ProductStatus.published.rawValue),
                     images: [.fake().copy(imageID: 1)])
    }

    private let sampleImage = UIImage.gridicon(.calendar, size: .init(width: 600, height: 600))

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

    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!

    override func setUp() {
        super.setUp()
        stores = MockStoresManager(sessionManager: .makeForTesting(defaultSite: Site.fake().copy(url: sampleSiteAddress)))
        storageManager = MockStorageManager()
        imageLoader = MockProductUIImageLoader()
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
    }

    override func tearDown() {
        analytics = nil
        analyticsProvider = nil
        imageLoader = nil
        storageManager = nil
        stores = nil
        super.tearDown()
    }

    // MARK: Initial values
    func test_image_is_empty_initially() throws {
        // Given
        insertProduct(sampleProduct)
        let viewModel = BlazeCampaignCreationFormViewModel(siteID: sampleSiteID,
                                                           productID: sampleProductID,
                                                           stores: stores,
                                                           storage: storageManager,
                                                           productImageLoader: imageLoader,
                                                           onCompletion: {})

        // Then
        XCTAssertNil(viewModel.image)
    }

    func test_tagline_is_empty_initially() throws {
        // Given
        insertProduct(sampleProduct)
        let viewModel = BlazeCampaignCreationFormViewModel(siteID: sampleSiteID,
                                                           productID: sampleProductID,
                                                           stores: stores,
                                                           storage: storageManager,
                                                           productImageLoader: imageLoader,
                                                           onCompletion: {})

        // Then
        XCTAssertEqual(viewModel.tagline, "")
    }

    func test_description_is_empty_initially() throws {
        // Given
        insertProduct(sampleProduct)
        let viewModel = BlazeCampaignCreationFormViewModel(siteID: sampleSiteID,
                                                           productID: sampleProductID,
                                                           stores: stores,
                                                           storage: storageManager,
                                                           productImageLoader: imageLoader,
                                                           onCompletion: {})

        // Then
        XCTAssertEqual(viewModel.description, "")
    }

    func test_ad_destination_product_url_is_updated_correctly_if_empty() throws {
        // Given
        insertProduct(sampleProduct.copy(permalink: ""))
        let viewModel = BlazeCampaignCreationFormViewModel(siteID: sampleSiteID,
                                                           productID: sampleProductID,
                                                           stores: stores,
                                                           storage: storageManager,
                                                           productImageLoader: imageLoader,
                                                           onCompletion: {})

        // Then
        XCTAssertEqual(viewModel.adDestinationViewModel?.productURL, sampleSiteAddress + "?post_type=product&p=\(sampleProductID)")
    }

    func test_hasEndDate_is_true_when_feature_flag_is_disabled() {
        // Given
        insertProduct(sampleProduct)
        let featureFlagService = MockFeatureFlagService(blazeEvergreenCampaigns: false)
        let viewModel = BlazeCampaignCreationFormViewModel(siteID: sampleSiteID,
                                                           productID: sampleProductID,
                                                           stores: stores,
                                                           storage: storageManager,
                                                           productImageLoader: imageLoader,
                                                           featureFlagService: featureFlagService,
                                                           onCompletion: {})

        // Then
        XCTAssertTrue(viewModel.budgetSettingViewModel.hasEndDate)
    }

    func test_hasEndDate_is_false_when_feature_flag_is_enabled() {
        // Given
        insertProduct(sampleProduct)
        let featureFlagService = MockFeatureFlagService(blazeEvergreenCampaigns: true)
        let viewModel = BlazeCampaignCreationFormViewModel(siteID: sampleSiteID,
                                                           productID: sampleProductID,
                                                           stores: stores,
                                                           storage: storageManager,
                                                           productImageLoader: imageLoader,
                                                           featureFlagService: featureFlagService,
                                                           onCompletion: {})

        // Then
        XCTAssertFalse(viewModel.budgetSettingViewModel.hasEndDate)
    }

    // MARK: On load
    @MainActor
    func test_onLoad_fetches_AI_suggestions() async throws {
        // Given
        insertProduct(sampleProduct)
        mockDownloadImage(sampleImage)
        var triggeredFetchAISuggestions = false
        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            switch action {
            case let .fetchAISuggestions(_, _, completion):
                triggeredFetchAISuggestions = true
                completion(.success([.fake()]))
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }
        let viewModel = BlazeCampaignCreationFormViewModel(siteID: sampleSiteID,
                                               productID: sampleProductID,
                                               stores: stores,
                                               storage: storageManager,
                                               productImageLoader: imageLoader,
                                               onCompletion: {})

        // When
        await viewModel.onLoad()

        // Then
        XCTAssertTrue(triggeredFetchAISuggestions)
    }

    @MainActor
    func test_onLoad_downloads_image() async throws {
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
        await viewModel.onLoad()

        // Then
        XCTAssertNotNil(imageLoader.imageRequestedForProductImage)
    }

    // MARK: Download product image
    @MainActor
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
    @MainActor
    func test_ad_can_be_edited_if_suggestions_failed_to_load() async throws {
        // Given
        insertProduct(sampleProduct)
        mockAISuggestionsFailure(MockError())
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

    @MainActor
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
    @MainActor
    func test_loadAISuggestions_sends_correct_product_ID_to_fetch() async throws {
        // Given
        insertProduct(sampleProduct)

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
                                                           storage: storageManager,
                                                           productImageLoader: imageLoader,
                                                           onCompletion: {})

        // When
        await viewModel.loadAISuggestions()

        // Then
        XCTAssertEqual(expectedProductID, sampleProductID)
    }
    @MainActor
    func test_loadAISuggestions_sets_tagline_and_description_upon_success() async throws {
        // Given
        insertProduct(sampleProduct)

        mockAISuggestionsSuccess(sampleAISuggestions)
        let viewModel = BlazeCampaignCreationFormViewModel(siteID: sampleSiteID,
                                                           productID: sampleProductID,
                                                           stores: stores,
                                                           storage: storageManager,
                                                           productImageLoader: imageLoader,
                                                           onCompletion: {})

        // When
        await viewModel.loadAISuggestions()

        // Then
        let firstSuggestion = try XCTUnwrap(sampleAISuggestions.first)
        XCTAssertEqual(viewModel.tagline, firstSuggestion.siteName)
        XCTAssertEqual(viewModel.description, firstSuggestion.textSnippet)
    }

    @MainActor
    func test_loadAISuggestions_sets_error_if_request_fails() async throws {
        // Given
        insertProduct(sampleProduct)

        mockAISuggestionsFailure(MockError())
        let viewModel = BlazeCampaignCreationFormViewModel(siteID: sampleSiteID,
                                                           productID: sampleProductID,
                                                           stores: stores,
                                                           storage: storageManager,
                                                           productImageLoader: imageLoader,
                                                           onCompletion: {})

        // When
        await viewModel.loadAISuggestions()

        // Then
        XCTAssertEqual(viewModel.error, .failedToLoadAISuggestions)
    }

    @MainActor
    func test_loadAISuggestions_sets_error_if_no_suggestions_available() async throws {
        // Given
        insertProduct(sampleProduct)

        mockAISuggestionsSuccess([])
        let viewModel = BlazeCampaignCreationFormViewModel(siteID: sampleSiteID,
                                                           productID: sampleProductID,
                                                           stores: stores,
                                                           storage: storageManager,
                                                           productImageLoader: imageLoader,
                                                           onCompletion: {})

        // When
        await viewModel.loadAISuggestions()

        // Then
        XCTAssertEqual(viewModel.error, .failedToLoadAISuggestions)
    }

    // MARK: `isUsingAISuggestions`
    @MainActor
    func test_isUsingAISuggestions_updates_correctly_after_fetching_AI_suggestions() async throws {
        // Given
        insertProduct(sampleProduct)

        mockAISuggestionsSuccess(sampleAISuggestions)
        let viewModel = BlazeCampaignCreationFormViewModel(siteID: sampleSiteID,
                                                           productID: sampleProductID,
                                                           stores: stores,
                                                           storage: storageManager,
                                                           productImageLoader: imageLoader,
                                                           onCompletion: {})

        // Then
        XCTAssertFalse(viewModel.isUsingAISuggestions, "Initially, isUsingAISuggestions should be false.")

        // When
        await viewModel.loadAISuggestions()

        // Then
        XCTAssertTrue(viewModel.isUsingAISuggestions, "After setting AI suggestions, isUsingAISuggestions should be true.")
    }

    @MainActor
    func test_isUsingAISuggestions_updates_correctly_after_editing_suggestions() async throws {
        // Given
        insertProduct(sampleProduct)

        mockAISuggestionsSuccess(sampleAISuggestions)
        let viewModel = BlazeCampaignCreationFormViewModel(siteID: sampleSiteID,
                                                           productID: sampleProductID,
                                                           stores: stores,
                                                           storage: storageManager,
                                                           productImageLoader: imageLoader,
                                                           onCompletion: {})

        await viewModel.loadAISuggestions()

        // Then
        XCTAssertTrue(viewModel.isUsingAISuggestions, "After setting AI suggestions, isUsingAISuggestions should be true.")

        // When
        let editAdViewModel = viewModel.editAdViewModel
        editAdViewModel.tagline = "Custom tagline"
        editAdViewModel.description = "Custom description"
        editAdViewModel.didTapSave()

        // Then
        XCTAssertFalse(viewModel.isUsingAISuggestions, "After setting AI suggestions, isUsingAISuggestions should be true.")
    }

    // MARK: `canConfirmDetails`
    @MainActor
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

    @MainActor
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


    // MARK: `didTapConfirmDetails`
    @MainActor
    func test_it_shows_error_if_confirmed_without_image() async throws {
        // Given
        insertProduct(sampleProduct)
        mockAISuggestionsSuccess(sampleAISuggestions)
        // No image set
        mockDownloadImage(nil)

        let viewModel = BlazeCampaignCreationFormViewModel(siteID: sampleSiteID,
                                                           productID: sampleProductID,
                                                           stores: stores,
                                                           storage: storageManager,
                                                           productImageLoader: imageLoader,
                                                           analytics: analytics,
                                                           onCompletion: {})
        await viewModel.downloadProductImage()

        await viewModel.loadAISuggestions()

        // When
        viewModel.didTapConfirmDetails()

        // Then
        XCTAssertTrue(viewModel.isShowingMissingImageErrorAlert)
    }

    // MARK: Analytics
    @MainActor
    func test_event_is_tracked_on_appear() async throws {
        // Given
        insertProduct(sampleProduct)
        let viewModel = BlazeCampaignCreationFormViewModel(siteID: sampleSiteID,
                                                           productID: sampleProductID,
                                                           stores: stores,
                                                           storage: storageManager,
                                                           productImageLoader: imageLoader,
                                                           analytics: analytics,
                                                           onCompletion: {})
        // When
        viewModel.onAppear()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("blaze_creation_form_displayed"))
    }

    @MainActor
    func test_displayed_event_is_tracked_only_once() async throws {
        // Given
        insertProduct(sampleProduct)
        let viewModel = BlazeCampaignCreationFormViewModel(siteID: sampleSiteID,
                                                           productID: sampleProductID,
                                                           stores: stores,
                                                           storage: storageManager,
                                                           productImageLoader: imageLoader,
                                                           analytics: analytics,
                                                           onCompletion: {})
        // When
        viewModel.onAppear()
        viewModel.onAppear()


        // Then
        XCTAssertEqual(analyticsProvider.receivedEvents.filter { $0 == "blaze_creation_form_displayed"}.count, 1)
    }

    @MainActor
    func test_event_is_tracked_upon_tapping_edit_ad() async throws {
        // Given
        insertProduct(sampleProduct)
        let viewModel = BlazeCampaignCreationFormViewModel(siteID: sampleSiteID,
                                                           productID: sampleProductID,
                                                           stores: stores,
                                                           storage: storageManager,
                                                           productImageLoader: imageLoader,
                                                           analytics: analytics,
                                                           onCompletion: {})
        // When
        viewModel.didTapEditAd()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("blaze_creation_edit_ad_tapped"))
    }

    @MainActor
    func test_event_is_tracked_upon_tapping_confirm_details_with_AI_suggested_content() async throws {
        // Given
        insertProduct(sampleProduct)
        mockAISuggestionsSuccess(sampleAISuggestions)
        mockDownloadImage(sampleImage)

        let viewModel = BlazeCampaignCreationFormViewModel(siteID: sampleSiteID,
                                                           productID: sampleProductID,
                                                           stores: stores,
                                                           storage: storageManager,
                                                           productImageLoader: imageLoader,
                                                           analytics: analytics,
                                                           onCompletion: {})
        // Sets non-nil product image
        await viewModel.downloadProductImage()

        await viewModel.loadAISuggestions()

        // When
        viewModel.didTapConfirmDetails()

        // Then
        let index = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(of: "blaze_creation_confirm_details_tapped"))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[index])
        let isAISuggested = try XCTUnwrap(eventProperties["is_ai_suggested_ad_content"] as? Bool)
        XCTAssertTrue(isAISuggested)
    }

    @MainActor
    func test_event_is_tracked_upon_tapping_confirm_details_with_custom_tagline() async throws {
        // Given
        insertProduct(sampleProduct)
        mockAISuggestionsSuccess(sampleAISuggestions)
        mockDownloadImage(sampleImage)

        let viewModel = BlazeCampaignCreationFormViewModel(siteID: sampleSiteID,
                                                           productID: sampleProductID,
                                                           stores: stores,
                                                           storage: storageManager,
                                                           productImageLoader: imageLoader,
                                                           analytics: analytics,
                                                           onCompletion: {})
        // Sets non-nil product image
        await viewModel.downloadProductImage()

        await viewModel.loadAISuggestions()

        let editAdViewModel = viewModel.editAdViewModel
        editAdViewModel.tagline = "Custom tagline"
        editAdViewModel.didTapSave()

        // When
        viewModel.didTapConfirmDetails()

        // Then
        let index = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(of: "blaze_creation_confirm_details_tapped"))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[index])
        let isAISuggested = try XCTUnwrap(eventProperties["is_ai_suggested_ad_content"] as? Bool)
        XCTAssertTrue(isAISuggested)
    }

    @MainActor
    func test_event_is_tracked_upon_tapping_confirm_details_with_custom_description() async throws {
        // Given
        insertProduct(sampleProduct)
        mockAISuggestionsSuccess(sampleAISuggestions)
        mockDownloadImage(sampleImage)

        let viewModel = BlazeCampaignCreationFormViewModel(siteID: sampleSiteID,
                                                           productID: sampleProductID,
                                                           stores: stores,
                                                           storage: storageManager,
                                                           productImageLoader: imageLoader,
                                                            analytics: analytics,
                                                           onCompletion: {})
        // Sets non-nil product image
        await viewModel.downloadProductImage()

        await viewModel.loadAISuggestions()

        let editAdViewModel = viewModel.editAdViewModel
        editAdViewModel.description = "Custom description"
        editAdViewModel.didTapSave()

        // When
        viewModel.didTapConfirmDetails()

        // Then
        let index = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(of: "blaze_creation_confirm_details_tapped"))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[index])
        let isAISuggested = try XCTUnwrap(eventProperties["is_ai_suggested_ad_content"] as? Bool)
        XCTAssertTrue(isAISuggested)
    }

    @MainActor
    func test_event_is_tracked_upon_tapping_confirm_details_with_custom_tagline_and_description() async throws {
        // Given
        insertProduct(sampleProduct)
        mockAISuggestionsSuccess(sampleAISuggestions)
        mockDownloadImage(sampleImage)

        let viewModel = BlazeCampaignCreationFormViewModel(siteID: sampleSiteID,
                                                           productID: sampleProductID,
                                                           stores: stores,
                                                           storage: storageManager,
                                                           productImageLoader: imageLoader,
                                                           analytics: analytics,
                                                           onCompletion: {})
        // Sets non-nil product image
        await viewModel.downloadProductImage()

        await viewModel.loadAISuggestions()

        let editAdViewModel = viewModel.editAdViewModel
        editAdViewModel.tagline = "Custom tagline"
        editAdViewModel.description = "Custom description"
        editAdViewModel.didTapSave()

        // When
        viewModel.didTapConfirmDetails()

        // Then
        let index = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(of: "blaze_creation_confirm_details_tapped"))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[index])
        let isAISuggested = try XCTUnwrap(eventProperties["is_ai_suggested_ad_content"] as? Bool)
        XCTAssertFalse(isAISuggested)
    }

    @MainActor
    func test_event_is_tracked_upon_tapping_confirm_details_with_correct_campaign_type_when_no_end_date_is_specified() async throws {
        // Given
        insertProduct(sampleProduct)
        mockAISuggestionsSuccess(sampleAISuggestions)
        mockDownloadImage(sampleImage)

        let viewModel = BlazeCampaignCreationFormViewModel(siteID: sampleSiteID,
                                                           productID: sampleProductID,
                                                           stores: stores,
                                                           storage: storageManager,
                                                           productImageLoader: imageLoader,
                                                           analytics: analytics,
                                                           onCompletion: {})
        // Sets non-nil product image
        await viewModel.downloadProductImage()

        // When
        // set evergreen
        viewModel.budgetSettingViewModel.hasEndDate = false
        viewModel.budgetSettingViewModel.confirmSettings()
        viewModel.didTapConfirmDetails()

        // Then
        let index = try XCTUnwrap(analyticsProvider.receivedEvents.lastIndex(of: "blaze_creation_confirm_details_tapped"))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[index])
        let campaignType = try XCTUnwrap(eventProperties["campaign_type"] as? String)
        XCTAssertEqual(campaignType, "evergreen")
    }

    @MainActor
    func test_event_is_tracked_upon_tapping_confirm_details_with_correct_campaign_type_when_end_date_is_specified() async throws {
        // Given
        insertProduct(sampleProduct)
        mockAISuggestionsSuccess(sampleAISuggestions)
        mockDownloadImage(sampleImage)

        let viewModel = BlazeCampaignCreationFormViewModel(siteID: sampleSiteID,
                                                           productID: sampleProductID,
                                                           stores: stores,
                                                           storage: storageManager,
                                                           productImageLoader: imageLoader,
                                                           analytics: analytics,
                                                           onCompletion: {})
        // Sets non-nil product image
        await viewModel.downloadProductImage()

        // When
        // set non-evergreen
        viewModel.budgetSettingViewModel.hasEndDate = true
        viewModel.budgetSettingViewModel.confirmSettings()
        viewModel.didTapConfirmDetails()

        // Then
        let index = try XCTUnwrap(analyticsProvider.receivedEvents.lastIndex(of: "blaze_creation_confirm_details_tapped"))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[index])
        let campaignType = try XCTUnwrap(eventProperties["campaign_type"] as? String)
        XCTAssertEqual(campaignType, "start_end")
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
}

private final class MockError: Error { }

private class MockProductUIImageLoader: ProductUIImageLoader {
    var imageRequestedForProductImage: Yosemite.ProductImage?
    var requestImageStubbedResponse: UIImage?

    func requestImage(productImage: ProductImage) async throws -> UIImage {
        imageRequestedForProductImage = productImage
        if let requestImageStubbedResponse {
            return requestImageStubbedResponse
        } else {
            throw MockError()
        }
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

    func mockAISuggestionsFailure(_ error: Error) {
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
