import Combine
import XCTest
import Yosemite
import class Photos.PHAsset
@testable import WooCommerce
import enum Networking.NetworkError

final class BlazeConfirmPaymentViewModelTests: XCTestCase {

    private let sampleProductID: Int64 = 123

    private let sampleSiteID: Int64 = 122

    private let samplePaymentMethod = BlazePaymentMethod(id: "test-id",
                                                         rawType: "credit-card",
                                                         name: "Card ending in 7284",
                                                         info: .init(lastDigits: "7284",
                                                                     expiring: .fake(),
                                                                     type: "Mastercard",
                                                                     nickname: nil,
                                                                     cardholderName: "Jane Doe"))

    private var stores: MockStoresManager!

    private var subscription: AnyCancellable?

    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!

    override func setUp() {
        super.setUp()
        stores = MockStoresManager(sessionManager: .makeForTesting())
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
    }

    override func tearDown() {
        analytics = nil
        analyticsProvider = nil
        stores = nil
        super.tearDown()
    }

    func test_totalAmount_and_totalAmountWithCurrency_are_correct_for_evergreen_campaign() {
        // Given
        let campaignInfo = CreateBlazeCampaign.fake().copy(budget: .init(mode: .daily, amount: 11, currency: "USD"), isEvergreen: true)
        let viewModel = BlazeConfirmPaymentViewModel(productID: sampleProductID,
                                                     siteID: sampleSiteID,
                                                     campaignInfo: campaignInfo,
                                                     image: .init(image: .init(), source: .productImage(image: .fake())),
                                                     stores: stores) {}

        // Then
        XCTAssertEqual(viewModel.totalAmount, "$77 weekly")
        XCTAssertEqual(viewModel.totalAmountWithCurrency, "$77 USD weekly")
    }

    func test_totalAmount_and_totalAmountWithCurrency_are_correct_for_non_evergreen_campaign() {
        // Given
        let campaignInfo = CreateBlazeCampaign.fake().copy(budget: .init(mode: .total, amount: 35, currency: "USD"), isEvergreen: false)
        let viewModel = BlazeConfirmPaymentViewModel(productID: sampleProductID,
                                                     siteID: sampleSiteID,
                                                     campaignInfo: campaignInfo,
                                                     image: .init(image: .init(), source: .productImage(image: .fake())),
                                                     stores: stores) {}

        // Then
        XCTAssertEqual(viewModel.totalAmount, "$35")
        XCTAssertEqual(viewModel.totalAmountWithCurrency, "$35 USD")
    }

    func test_isFetchingPaymentInfo_is_updated_correctly_when_fetching_payment_info() async {
        // Given
        let viewModel = BlazeConfirmPaymentViewModel(productID: sampleProductID,
                                                     siteID: sampleSiteID,
                                                     campaignInfo: .fake(),
                                                     image: .init(image: .init(), source: .productImage(image: .fake())),
                                                     stores: stores) {}
        var fetchingStates: [Bool] = []
        subscription = viewModel.$isFetchingPaymentInfo
            .sink { isFetching in
                fetchingStates.append(isFetching)
            }

        // When
        mockPaymentFetch(with: .success(.fake()))
        await viewModel.updatePaymentInfo()

        // Then
        XCTAssertEqual(fetchingStates, [false, true, false])
    }

    func test_shouldDisplayPaymentErrorAlert_is_true_when_fetching_payment_info_fails() async {
        // Given
        let viewModel = BlazeConfirmPaymentViewModel(productID: sampleProductID,
                                                     siteID: sampleSiteID,
                                                     campaignInfo: .fake(),
                                                     image: .init(image: .init(), source: .productImage(image: .fake())),
                                                     stores: stores) {}
        XCTAssertFalse(viewModel.shouldDisplayPaymentErrorAlert)

        // When
        mockPaymentFetch(with: .failure(NSError(domain: "Test", code: 500)))
        await viewModel.updatePaymentInfo()

        // Then
        XCTAssertTrue(viewModel.shouldDisplayPaymentErrorAlert)
    }

    func test_shouldDisableCampaignCreation_is_false_until_a_selected_payment_method_is_found() async {
        // Given
        let viewModel = BlazeConfirmPaymentViewModel(productID: sampleProductID,
                                                     siteID: sampleSiteID,
                                                     campaignInfo: .fake(),
                                                     image: .init(image: .init(), source: .productImage(image: .fake())),
                                                     stores: stores) {}
        let paymentMethod = BlazePaymentMethod(id: "test-id", rawType: "credit-card", name: "Card ending in 7284", info: .fake())
        XCTAssertTrue(viewModel.shouldDisableCampaignCreation)

        // When
        mockPaymentFetch(with: .success(.fake().copy(paymentMethods: [paymentMethod])))
        await viewModel.updatePaymentInfo()

        // Then
        XCTAssertFalse(viewModel.shouldDisableCampaignCreation)
    }

    func test_card_details_are_correct_if_a_selected_payment_method_is_found() async {
        // Given
        let viewModel = BlazeConfirmPaymentViewModel(productID: sampleProductID,
                                                     siteID: sampleSiteID,
                                                     campaignInfo: .fake(),
                                                     image: .init(image: .init(), source: .productImage(image: .fake())),
                                                     stores: stores) {}
        let paymentMethod = BlazePaymentMethod(id: "test-id",
                                               rawType: "credit-card",
                                               name: "Card ending in 7284",
                                               info: .init(lastDigits: "7284",
                                                           expiring: .fake(),
                                                           type: "Mastercard",
                                                           nickname: nil,
                                                           cardholderName: "Jane Doe"))

        // When
        mockPaymentFetch(with: .success(.fake().copy(paymentMethods: [paymentMethod])))
        await viewModel.updatePaymentInfo()

        // Then
        XCTAssertEqual(viewModel.cardIcon, UIImage(named: "card-brand-mastercard"))
        XCTAssertEqual(viewModel.cardTypeName, "Mastercard")
        XCTAssertEqual(viewModel.cardName, "Card ending in 7284")
    }

    func test_confirmPaymentDetails_does_not_trigger_campaign_creation_if_selectedPaymentMethod_is_nil() async {
        // Given
        let viewModel = BlazeConfirmPaymentViewModel(productID: sampleProductID,
                                                     siteID: sampleSiteID,
                                                     campaignInfo: .fake(),
                                                     image: .init(image: .init(), source: .productImage(image: .fake())),
                                                     stores: stores) {}
        var didTriggerCampaignCreation = false
        XCTAssertNil(viewModel.selectedPaymentMethod)

        // When
        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            switch action {
            case let .createCampaign(_, _, onCompletion):
                didTriggerCampaignCreation = true
                onCompletion(.success(Void()))
            default:
                break
            }
        }
        await viewModel.submitCampaign()

        // Then
        XCTAssertFalse(didTriggerCampaignCreation)
        XCTAssertFalse(viewModel.isCreatingCampaign)
        XCTAssertNil(viewModel.campaignCreationError)
    }

    func test_isCreatingCampaign_is_updated_correctly_when_creating_campaign() async {
        // Given
        let viewModel = BlazeConfirmPaymentViewModel(productID: sampleProductID,
                                                     siteID: sampleSiteID,
                                                     campaignInfo: .fake(),
                                                     image: .init(image: .init(), source: .productImage(image: .fake())),
                                                     stores: stores) {}
        var loadingStates: [Bool] = []
        subscription = viewModel.$isCreatingCampaign
            .sink { isLoading in
                loadingStates.append(isLoading)
            }

        // When
        mockRetrieveMedia(with: .success(.fake()))
        mockCampaignCreation(with: .success(Void()))
        await viewModel.updatePaymentInfo()
        await viewModel.submitCampaign()

        // Then
        XCTAssertEqual(loadingStates, [false, true, false])
    }

    func test_campaignCreationError_is_correct_when_campaign_creation_fails() async {
        // Given
        let viewModel = BlazeConfirmPaymentViewModel(productID: sampleProductID,
                                                     siteID: sampleSiteID,
                                                     campaignInfo: .fake(),
                                                     image: .init(image: .init(), source: .productImage(image: .fake())),
                                                     stores: stores) {}
        XCTAssertNil(viewModel.campaignCreationError)

        // When
        mockRetrieveMedia(with: .success(.fake()))
        mockCampaignCreation(with: .failure(NSError(domain: "test", code: 500)))
        await viewModel.updatePaymentInfo()
        await viewModel.submitCampaign()

        // Then
        XCTAssertEqual(viewModel.campaignCreationError, .failedToCreateCampaign)
    }

    func test_campaignCreationError_is_correct_when_image_size_error_happens() async {
        // Given
        let viewModel = BlazeConfirmPaymentViewModel(productID: sampleProductID,
                                                     siteID: sampleSiteID,
                                                     campaignInfo: .fake(),
                                                     image: .init(image: .init(), source: .productImage(image: .fake())),
                                                     stores: stores) {}
        XCTAssertNil(viewModel.campaignCreationError)

        // When
        mockRetrieveMedia(with: .success(.fake()))
        mockCampaignCreation(with: .failure(NetworkError.unacceptableStatusCode(statusCode: 422, response: nil)))
        await viewModel.updatePaymentInfo()
        await viewModel.submitCampaign()

        // Then
        XCTAssertEqual(viewModel.campaignCreationError, .insufficientImageSize)
    }

    func test_onCompletion_is_triggered_when_campaign_creation_succeeds() async {
        // Given
        var completionHandlerTriggered = false
        let viewModel = BlazeConfirmPaymentViewModel(productID: sampleProductID,
                                                     siteID: sampleSiteID,
                                                     campaignInfo: .fake(),
                                                     image: .init(image: .init(), source: .productImage(image: .fake())),
                                                     stores: stores) {
            completionHandlerTriggered = true
        }

        // When
        mockRetrieveMedia(with: .success(.fake()))
        mockCampaignCreation(with: .success(Void()))
        await viewModel.updatePaymentInfo()
        await viewModel.submitCampaign()

        // Then
        XCTAssertTrue(completionHandlerTriggered)
    }

    // MARK: Retrieve Media for product image

    func test_campaign_is_submitted_with_retrieved_media_src_and_mimeType() async throws {
        // Given
        let viewModel = BlazeConfirmPaymentViewModel(productID: sampleProductID,
                                                     siteID: sampleSiteID,
                                                     campaignInfo: .fake(),
                                                     image: .init(image: .init(), source: .productImage(image: .fake())),
                                                     stores: stores) {}

        // When
        let media = Media.fake().copy(mimeType: "image/jpeg", src: "http://example.com/test.jpeg")
        mockRetrieveMedia(with: .success(media))

        var submittedCampaign: CreateBlazeCampaign?
        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            switch action {
            case let .fetchPaymentInfo(_, onCompletion):
                onCompletion(.success(.fake().copy(paymentMethods: [self.samplePaymentMethod])))
            case let .createCampaign(campaign, _, onCompletion):
                submittedCampaign = campaign
                onCompletion(.success(Void()))
            default:
                break
            }
        }

        await viewModel.updatePaymentInfo()
        await viewModel.submitCampaign()

        // Then
        let campaign = try XCTUnwrap(submittedCampaign)
        XCTAssertEqual(campaign.mainImage.url, media.src)
        XCTAssertEqual(campaign.mainImage.mimeType, media.mimeType)
    }

    func test_campaignCreationError_is_correct_when_retrieve_media_fails() async {
        // Given
        let viewModel = BlazeConfirmPaymentViewModel(productID: sampleProductID,
                                                     siteID: sampleSiteID,
                                                     campaignInfo: .fake(),
                                                     image: .init(image: .init(), source: .productImage(image: .fake())),
                                                     stores: stores) {}
        XCTAssertNil(viewModel.campaignCreationError)

        // When
        mockRetrieveMedia(with: .failure(NSError(domain: "test", code: 500)))
        mockCampaignCreation(with: .success(Void()))
        await viewModel.updatePaymentInfo()
        await viewModel.submitCampaign()

        // Then
        XCTAssertEqual(viewModel.campaignCreationError, .failedToFetchCampaignImage)
    }

    // MARK: Upload image

    func test_campaign_is_submitted_with_uploaded_media_src_and_mimeType() async throws {
        // Given
        let viewModel = BlazeConfirmPaymentViewModel(productID: sampleProductID,
                                                     siteID: sampleSiteID,
                                                     campaignInfo: .fake(),
                                                     image: .init(image: .init(), source: .asset(asset: PHAsset())),
                                                     stores: stores) {}

        // When
        let media = Media.fake().copy(mimeType: "image/jpeg", src: "http://example.com/test.jpeg")
        mockUploadMedia(with: .success(media))

        var submittedCampaign: CreateBlazeCampaign?
        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            switch action {
            case let .fetchPaymentInfo(_, onCompletion):
                onCompletion(.success(.fake().copy(paymentMethods: [self.samplePaymentMethod])))
            case let .createCampaign(campaign, _, onCompletion):
                submittedCampaign = campaign
                onCompletion(.success(Void()))
            default:
                break
            }
        }

        await viewModel.updatePaymentInfo()
        await viewModel.submitCampaign()

        // Then
        let campaign = try XCTUnwrap(submittedCampaign)
        XCTAssertEqual(campaign.mainImage.url, media.src)
        XCTAssertEqual(campaign.mainImage.mimeType, media.mimeType)
    }

    func test_upload_image_is_retried_one_time_if_upload_fails() async throws {
        // Given
        let viewModel = BlazeConfirmPaymentViewModel(productID: sampleProductID,
                                                     siteID: sampleSiteID,
                                                     campaignInfo: .fake(),
                                                     image: .init(image: .init(), source: .asset(asset: PHAsset())),
                                                     stores: stores) {}

        // When
        mockUploadMedia(with: .failure(NetworkError.timeout(response: nil)))
        mockCampaignCreation(with: .success(Void()))

        await viewModel.updatePaymentInfo()
        await viewModel.submitCampaign()

        // Then
        var uploadMediaInvocationCount = 0
        for action in stores.receivedActions {
            guard let mediaAction = action as? MediaAction else {
                continue
            }
            switch mediaAction {
            case .uploadMedia:
                uploadMediaInvocationCount += 1
            default:
                continue
            }
        }
        XCTAssertEqual(uploadMediaInvocationCount, 2)
    }

    func test_campaignCreationError_is_correct_when_image_upload_fails() async {
        // Given
        let viewModel = BlazeConfirmPaymentViewModel(productID: sampleProductID,
                                                     siteID: sampleSiteID,
                                                     campaignInfo: .fake(),
                                                     image: .init(image: .init(), source: .asset(asset: PHAsset())),
                                                     stores: stores) {}
        XCTAssertNil(viewModel.campaignCreationError)

        // When
        mockUploadMedia(with: .failure(NSError(domain: "test", code: 500)))
        mockCampaignCreation(with: .success(Void()))
        await viewModel.updatePaymentInfo()
        await viewModel.submitCampaign()

        // Then
        XCTAssertEqual(viewModel.campaignCreationError, .failedToUploadCampaignImage)
    }

    // MARK: Add payment from web view

    func test_payment_info_is_fetched_when_new_payment_method_added_from_web_view() async throws {
        // Given
        let viewModel = BlazeConfirmPaymentViewModel(productID: sampleProductID,
                                                     siteID: sampleSiteID,
                                                     campaignInfo: .fake(),
                                                     image: .init(image: .init(), source: .productImage(image: .fake())),
                                                     stores: stores) {}
        viewModel.showAddPaymentSheet = true
        let samplePaymentInfo: BlazePaymentInfo = BlazePaymentMethodsViewModel.samplePaymentInfo()
        mockPaymentFetch(with: .success(samplePaymentInfo))
        await viewModel.updatePaymentInfo()

        var didTriggerFetchPaymentInfo = false
        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            switch action {
            case let .fetchPaymentInfo(_, onCompletion):
                didTriggerFetchPaymentInfo = true
                onCompletion(.success(.fake()))
            default:
                break
            }
        }

        // When
        viewModel.addPaymentWebViewModel?.didAddNewPaymentMethod()

        // Then
        waitUntil {
            didTriggerFetchPaymentInfo == true
        }
    }

    // MARK: Add payment from payment method list screen

    func test_add_payment_web_view_is_dismissed_after_selecting_payment_method() async {
        // Given
        let viewModel = BlazeConfirmPaymentViewModel(productID: sampleProductID,
                                                     siteID: sampleSiteID,
                                                     campaignInfo: .fake(),
                                                     image: .init(image: .init(), source: .productImage(image: .fake())),
                                                     stores: stores) {}
        let samplePaymentInfo: BlazePaymentInfo = BlazePaymentMethodsViewModel.samplePaymentInfo()
        mockPaymentFetch(with: .success(samplePaymentInfo))
        await viewModel.updatePaymentInfo()

        viewModel.showAddPaymentSheet = true

        // When
        viewModel.paymentMethodsViewModel?.didSelectPaymentMethod(withID: "payment-method-1")

        // Then
        waitUntil {
            viewModel.showAddPaymentSheet == false
        }
    }

    func test_payment_info_is_fetched_when_new_payment_method_added() async {
        // Given
        let viewModel = BlazeConfirmPaymentViewModel(productID: sampleProductID,
                                                     siteID: sampleSiteID,
                                                     campaignInfo: .fake(),
                                                     image: .init(image: .init(), source: .productImage(image: .fake())),
                                                     stores: stores) {}
        viewModel.showAddPaymentSheet = true
        let samplePaymentInfo: BlazePaymentInfo = BlazePaymentMethodsViewModel.samplePaymentInfo()
        mockPaymentFetch(with: .success(samplePaymentInfo))
        await viewModel.updatePaymentInfo()

        var didTriggerFetchPaymentInfo = false
        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            switch action {
            case let .fetchPaymentInfo(_, onCompletion):
                didTriggerFetchPaymentInfo = true
                onCompletion(.success(.fake()))
            default:
                break
            }
        }

        // When
        viewModel.paymentMethodsViewModel?.didSelectPaymentMethod(withID: "new-payment-method")

        // Then
        waitUntil {
            didTriggerFetchPaymentInfo == true
        }
    }

    // MARK: Analytics
    func test_event_is_tracked_when_submitting_campaign() async throws {
        // Given
        let viewModel = BlazeConfirmPaymentViewModel(productID: sampleProductID,
                                                     siteID: sampleSiteID,
                                                     campaignInfo: .fake(),
                                                     image: .init(image: .init(), source: .productImage(image: .fake())),
                                                     stores: stores,
                                                     analytics: analytics) {}
        // When
        mockRetrieveMedia(with: .success(.fake()))
        mockCampaignCreation(with: .failure(NSError(domain: "test", code: 500)))
        await viewModel.updatePaymentInfo()

        // When
        await viewModel.submitCampaign()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("blaze_creation_payment_submit_campaign_tapped"))
    }

    func test_event_is_tracked_when_campaign_creation_successful_for_evergreen_campaign() async throws {
        // Given
        let viewModel = BlazeConfirmPaymentViewModel(productID: sampleProductID,
                                                     siteID: sampleSiteID,
                                                     campaignInfo: .fake().copy(isEvergreen: true),
                                                     image: .init(image: .init(), source: .productImage(image: .fake())),
                                                     stores: stores,
                                                     analytics: analytics) {}
        // When
        mockRetrieveMedia(with: .success(.fake()))
        mockCampaignCreation(with: .success(Void()))
        await viewModel.updatePaymentInfo()

        // When
        await viewModel.submitCampaign()

        // Then
        let index = try XCTUnwrap(analyticsProvider.receivedEvents.lastIndex(of: "blaze_campaign_creation_success"))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[index])
        XCTAssertEqual(eventProperties["campaign_type"] as? String, "evergreen")
    }

    func test_event_is_tracked_when_campaign_creation_successful_for_non_evergreen_campaign() async throws {
        // Given
        let viewModel = BlazeConfirmPaymentViewModel(productID: sampleProductID,
                                                     siteID: sampleSiteID,
                                                     campaignInfo: .fake().copy(isEvergreen: false),
                                                     image: .init(image: .init(), source: .productImage(image: .fake())),
                                                     stores: stores,
                                                     analytics: analytics) {}
        // When
        mockRetrieveMedia(with: .success(.fake()))
        mockCampaignCreation(with: .success(Void()))
        await viewModel.updatePaymentInfo()

        // When
        await viewModel.submitCampaign()

        // Then
        let index = try XCTUnwrap(analyticsProvider.receivedEvents.lastIndex(of: "blaze_campaign_creation_success"))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[index])
        XCTAssertEqual(eventProperties["campaign_type"] as? String, "start_end")
    }

    func test_event_is_tracked_when_campaign_creation_failed() async throws {
        // Given
        let viewModel = BlazeConfirmPaymentViewModel(productID: sampleProductID,
                                                     siteID: sampleSiteID,
                                                     campaignInfo: .fake(),
                                                     image: .init(image: .init(), source: .productImage(image: .fake())),
                                                     stores: stores,
                                                     analytics: analytics) {}
        // When
        mockRetrieveMedia(with: .success(.fake()))
        mockCampaignCreation(with: .failure(NSError(domain: "test", code: 500)))
        await viewModel.updatePaymentInfo()

        // When
        await viewModel.submitCampaign()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("blaze_campaign_creation_failed"))
    }
}

private extension BlazeConfirmPaymentViewModelTests {
    func mockPaymentFetch(with result: Result<BlazePaymentInfo, Error>) {
        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            switch action {
            case let .fetchPaymentInfo(_, onCompletion):
                onCompletion(result)
            default:
                break
            }
        }
    }

    func mockRetrieveMedia(with result: Result<Media, Error>) {
        stores.whenReceivingAction(ofType: MediaAction.self) { action in
            switch action {
            case let .retrieveMedia(_, _, onCompletion):
                onCompletion(result)
            default:
                break
            }
        }
    }

    func mockUploadMedia(with result: Result<Media, Error>) {
        stores.whenReceivingAction(ofType: MediaAction.self) { action in
            switch action {
            case let .uploadMedia(_, _, _, _, _, onCompletion):
                onCompletion(result)
            default:
                break
            }
        }
    }

    func mockCampaignCreation(with result: Result<Void, Error>) {
        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            switch action {
            case let .fetchPaymentInfo(_, onCompletion):
                onCompletion(.success(.fake().copy(paymentMethods: [self.samplePaymentMethod])))
            case let .createCampaign(_, _, onCompletion):
                onCompletion(result)
            default:
                break
            }
        }
    }
}
