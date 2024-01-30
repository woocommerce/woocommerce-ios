import Combine
import XCTest
import Yosemite
@testable import WooCommerce

final class BlazeConfirmPaymentViewModelTests: XCTestCase {

    private let sampleSiteID: Int64 = 122

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

    func test_isFetchingPaymentInfo_is_updated_correctly_when_fetching_payment_info() async {
        // Given
        let viewModel = BlazeConfirmPaymentViewModel(siteID: sampleSiteID, campaignInfo: .fake(), stores: stores) {}
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
        let viewModel = BlazeConfirmPaymentViewModel(siteID: sampleSiteID, campaignInfo: .fake(), stores: stores) {}
        XCTAssertFalse(viewModel.shouldDisplayPaymentErrorAlert)

        // When
        mockPaymentFetch(with: .failure(NSError(domain: "Test", code: 500)))
        await viewModel.updatePaymentInfo()

        // Then
        XCTAssertTrue(viewModel.shouldDisplayPaymentErrorAlert)
    }

    func test_shouldDisableCampaignCreation_is_false_until_a_selected_payment_method_is_found() async {
        // Given
        let viewModel = BlazeConfirmPaymentViewModel(siteID: sampleSiteID, campaignInfo: .fake(), stores: stores) {}
        let paymentMethod = BlazePaymentMethod(id: "test-id", rawType: "credit-card", name: "Card ending in 7284", info: .fake())
        XCTAssertTrue(viewModel.shouldDisableCampaignCreation)

        // When
        mockPaymentFetch(with: .success(.fake().copy(savedPaymentMethods: [paymentMethod])))
        await viewModel.updatePaymentInfo()

        // Then
        XCTAssertFalse(viewModel.shouldDisableCampaignCreation)
    }

    func test_card_details_are_correct_if_a_selected_payment_method_is_found() async {
        // Given
        let viewModel = BlazeConfirmPaymentViewModel(siteID: sampleSiteID, campaignInfo: .fake(), stores: stores) {}
        let paymentMethod = BlazePaymentMethod(id: "test-id",
                                               rawType: "credit-card",
                                               name: "Card ending in 7284",
                                               info: .init(lastDigits: "7284",
                                                           expiring: .fake(),
                                                           type: "Mastercard",
                                                           nickname: nil,
                                                           cardholderName: "Jane Doe"))

        // When
        mockPaymentFetch(with: .success(.fake().copy(savedPaymentMethods: [paymentMethod])))
        await viewModel.updatePaymentInfo()

        // Then
        XCTAssertEqual(viewModel.cardIcon, UIImage(named: "card-brand-mastercard"))
        XCTAssertEqual(viewModel.cardTypeName, "Mastercard")
        XCTAssertEqual(viewModel.cardName, "Card ending in 7284")
    }

    func test_confirmPaymentDetails_does_not_trigger_campaign_creation_if_selectedPaymentMethod_is_nil() async {
        // Given
        let viewModel = BlazeConfirmPaymentViewModel(siteID: sampleSiteID, campaignInfo: .fake(), stores: stores) {}
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
        XCTAssertFalse(viewModel.shouldDisplayCampaignCreationError)
    }

    func test_isCreatingCampaign_is_updated_correctly_when_creating_campaign() async {
        // Given
        let viewModel = BlazeConfirmPaymentViewModel(siteID: sampleSiteID, campaignInfo: .fake(), stores: stores) {}
        var loadingStates: [Bool] = []
        subscription = viewModel.$isCreatingCampaign
            .sink { isLoading in
                loadingStates.append(isLoading)
            }

        // When
        mockCampaignCreation(with: .success(Void()))
        await viewModel.updatePaymentInfo()
        await viewModel.submitCampaign()

        // Then
        XCTAssertEqual(loadingStates, [false, true, false])
    }

    func test_shouldDisplayCampaignCreationError_is_correct_when_campaign_creation_fails() async {
        // Given
        let viewModel = BlazeConfirmPaymentViewModel(siteID: sampleSiteID, campaignInfo: .fake(), stores: stores) {}
        XCTAssertFalse(viewModel.shouldDisplayCampaignCreationError)

        // When
        mockCampaignCreation(with: .failure(NSError(domain: "test", code: 500)))
        await viewModel.updatePaymentInfo()
        await viewModel.submitCampaign()

        // Then
        XCTAssertTrue(viewModel.shouldDisplayCampaignCreationError)
    }

    func test_onCompletion_is_triggered_when_campaign_creation_succeeds() async {
        // Given
        var completionHandlerTriggered = false
        let viewModel = BlazeConfirmPaymentViewModel(siteID: sampleSiteID, campaignInfo: .fake(), stores: stores) {
            completionHandlerTriggered = true
        }

        // When
        mockCampaignCreation(with: .success(Void()))
        await viewModel.updatePaymentInfo()
        await viewModel.submitCampaign()

        // Then
        XCTAssertTrue(completionHandlerTriggered)
    }

    // MARK: Add payment from web view

    func test_payment_info_is_fetched_when_new_payment_method_added_from_web_view() async throws {
        // Given
        let viewModel = BlazeConfirmPaymentViewModel(siteID: sampleSiteID, campaignInfo: .fake(), stores: stores) {}
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
        let successURL = try XCTUnwrap(URL(string: "\(samplePaymentInfo.addPaymentMethod.successUrl)?\(samplePaymentInfo.addPaymentMethod.idUrlParameter)=123"))
        viewModel.addPaymentWebViewModel?.didAddNewPaymentMethod(successURL: successURL)

        // Then
        waitUntil {
            didTriggerFetchPaymentInfo == true
        }
    }

    // MARK: Add payment from payment method list screen

    func test_add_payment_web_view_is_dismissed_after_selecting_payment_method() async {
        // Given
        let viewModel = BlazeConfirmPaymentViewModel(siteID: sampleSiteID, campaignInfo: .fake(), stores: stores) {}
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
        let viewModel = BlazeConfirmPaymentViewModel(siteID: sampleSiteID, campaignInfo: .fake(), stores: stores) {}
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
        let viewModel = BlazeConfirmPaymentViewModel(siteID: sampleSiteID,
                                                     campaignInfo: .fake(),
                                                     stores: stores,
                                                     analytics: analytics) {}
        // When
        mockCampaignCreation(with: .failure(NSError(domain: "test", code: 500)))
        await viewModel.updatePaymentInfo()

        // When
        await viewModel.submitCampaign()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("blaze_creation_payment_submit_campaign_tapped"))
    }

    func test_event_is_tracked_when_campaign_creation_successful() async throws {
        // Given
        let viewModel = BlazeConfirmPaymentViewModel(siteID: sampleSiteID,
                                                     campaignInfo: .fake(),
                                                     stores: stores,
                                                     analytics: analytics) {}
        // When
        mockCampaignCreation(with: .success(Void()))
        await viewModel.updatePaymentInfo()

        // When
        await viewModel.submitCampaign()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("blaze_campaign_creation_success"))
    }

    func test_event_is_tracked_when_campaign_creation_failed() async throws {
        // Given
        let viewModel = BlazeConfirmPaymentViewModel(siteID: sampleSiteID,
                                                     campaignInfo: .fake(),
                                                     stores: stores,
                                                     analytics: analytics) {}
        // When
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

    func mockCampaignCreation(with result: Result<Void, Error>) {
        let paymentMethod = BlazePaymentMethod(id: "test-id",
                                               rawType: "credit-card",
                                               name: "Card ending in 7284",
                                               info: .init(lastDigits: "7284",
                                                           expiring: .fake(),
                                                           type: "Mastercard",
                                                           nickname: nil,
                                                           cardholderName: "Jane Doe"))
        stores.whenReceivingAction(ofType: BlazeAction.self) { action in
            switch action {
            case let .fetchPaymentInfo(_, onCompletion):
                onCompletion(.success(.fake().copy(savedPaymentMethods: [paymentMethod])))
            case let .createCampaign(_, _, onCompletion):
                onCompletion(result)
            default:
                break
            }
        }
    }
}
