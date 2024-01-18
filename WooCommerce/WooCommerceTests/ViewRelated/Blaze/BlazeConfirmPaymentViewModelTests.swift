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
        let viewModel = BlazeConfirmPaymentViewModel(siteID: sampleSiteID, campaignInfo: .fake(), stores: stores)
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

    func test_shouldDisplayErrorAlert_is_true_when_fetching_payment_info_fails() async {
        // Given
        let viewModel = BlazeConfirmPaymentViewModel(siteID: sampleSiteID, campaignInfo: .fake(), stores: stores)
        XCTAssertFalse(viewModel.shouldDisplayErrorAlert)

        // When
        mockPaymentFetch(with: .failure(NSError(domain: "Test", code: 500)))
        await viewModel.updatePaymentInfo()

        // Then
        XCTAssertTrue(viewModel.shouldDisplayErrorAlert)
    }

    func test_shouldDisableCampaignCreation_is_false_until_a_selected_payment_method_is_found() async {
        // Given
        let viewModel = BlazeConfirmPaymentViewModel(siteID: sampleSiteID, campaignInfo: .fake(), stores: stores)
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
        let viewModel = BlazeConfirmPaymentViewModel(siteID: sampleSiteID, campaignInfo: .fake(), stores: stores)
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
}
