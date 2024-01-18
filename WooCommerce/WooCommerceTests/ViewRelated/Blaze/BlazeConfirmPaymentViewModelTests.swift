import Combine
import XCTest
import Yosemite
@testable import WooCommerce

final class BlazeConfirmPaymentViewModelTests: XCTestCase {

    private let sampleSiteID: Int64 = 122

    private var stores: MockStoresManager!

    private var subscription: AnyCancellable?

    override func setUp() {
        super.setUp()
        stores = MockStoresManager(sessionManager: .makeForTesting())
    }

    override func tearDown() {
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
        await viewModel.confirmPaymentDetails()

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
        await viewModel.confirmPaymentDetails()

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
        await viewModel.confirmPaymentDetails()

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
        await viewModel.confirmPaymentDetails()

        // Then
        XCTAssertTrue(completionHandlerTriggered)
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
