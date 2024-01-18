import Combine
import XCTest
import Yosemite
@testable import WooCommerce

@MainActor
final class BlazePaymentMethodsViewModelTests: XCTestCase {

    private let sampleSiteID: Int64 = 322

    private let samplePaymentInfo: BlazePaymentInfo = BlazePaymentMethodsViewModel.samplePaymentInfo()

    // Account related
    private let sampleDisplayName = "John Doe"
    private let sampleEmail = "test@example.com"
    private let sampleUsername = "johndoe"

    private var stores: MockStoresManager!

    private var subscription: AnyCancellable?

    override func setUp() {
        super.setUp()
        stores = MockStoresManager(sessionManager: SessionManager.makeForTesting(authenticated: true,
                                                                                 isWPCom: true,
                                                                                 displayName: sampleDisplayName,
                                                                                 email: sampleEmail,
                                                                                 username: sampleUsername))
    }

    // MARK: `paymentMethods`

    func test_paymentMethods_returns_savedPaymentMethods() async throws {
        // Given
        let viewModel = BlazePaymentMethodsViewModel(siteID: sampleSiteID,
                                                     paymentInfo: samplePaymentInfo,
                                                     selectedPaymentMethodID: "payment-method-1",
                                                     stores: stores) { _ in}

        // Then
        XCTAssertEqual(viewModel.paymentMethods, samplePaymentInfo.savedPaymentMethods)
    }

    // MARK: `selectedPaymentMethodID`
    func test_selectedPaymentMethodID_returns_injected_initial_value() async throws {
        // Given
        let viewModel = BlazePaymentMethodsViewModel(siteID: sampleSiteID,
                                                     paymentInfo: samplePaymentInfo,
                                                     selectedPaymentMethodID: "payment-method-1",
                                                     stores: stores) { _ in }

        // Then
        XCTAssertEqual(viewModel.selectedPaymentMethodID, "payment-method-1")
    }

    // MARK: Account related
    func test_account_details_reflect_the_logged_in_account() async throws {
        // Given
        let viewModel = BlazePaymentMethodsViewModel(siteID: sampleSiteID,
                                                     paymentInfo: samplePaymentInfo,
                                                     selectedPaymentMethodID: "payment-method-1",
                                                     stores: stores) { _ in }

        // Then
        XCTAssertEqual(viewModel.userEmail, sampleEmail)
        XCTAssertEqual(viewModel.WPCOMUsername, sampleUsername)
        XCTAssertEqual(viewModel.WPCOMEmail, sampleEmail)
    }

    // MARK: `addPaymentMethodURL`
    func test_addPaymentMethodURL_returns_formUrl() async throws {
        // Given
        let viewModel = BlazePaymentMethodsViewModel(siteID: sampleSiteID,
                                                     paymentInfo: samplePaymentInfo,
                                                     selectedPaymentMethodID: "payment-method-1",
                                                     stores: stores) { _ in }

        // Then
        XCTAssertEqual(viewModel.addPaymentMethodURL, URL(string: "https://example.com/blaze-pm-add")!)
    }

    // MARK: `fetchPaymentMethodURLPath`
    func test_fetchPaymentMethodURLPath_returns_successUrl() async throws {
        // Given
        let viewModel = BlazePaymentMethodsViewModel(siteID: sampleSiteID,
                                                     paymentInfo: samplePaymentInfo,
                                                     selectedPaymentMethodID: "payment-method-1",
                                                     stores: stores) { _ in }

        // Then
        XCTAssertEqual(viewModel.addPaymentSuccessURL, "https://example.com/blaze-pm-success")
    }

    // MARK: `isDoneButtonEnabled`
    func test_isDoneButtonEnabled_is_false_if_no_payment_methods_available() async throws {
        // Given
        let viewModel = BlazePaymentMethodsViewModel(siteID: sampleSiteID,
                                                     paymentInfo: samplePaymentInfo.copy(savedPaymentMethods: []),
                                                     selectedPaymentMethodID: nil,
                                                     stores: stores) { _ in }

        // Then
        XCTAssertFalse(viewModel.isDoneButtonEnabled)
    }

    func test_isDoneButtonEnabled_is_false_if_selection_not_changed() async throws {
        // Given
        let viewModel = BlazePaymentMethodsViewModel(siteID: sampleSiteID,
                                                     paymentInfo: samplePaymentInfo,
                                                     selectedPaymentMethodID: "payment-method-1",
                                                     stores: stores) { _ in }

        // When
        viewModel.didSelectPaymentMethod(withID: "payment-method-2")
        // Restore original selection
        viewModel.didSelectPaymentMethod(withID: "payment-method-1")

        // Then
        XCTAssertFalse(viewModel.isDoneButtonEnabled)
    }

    func test_isDoneButtonEnabled_is_true_if_selection_not_changed() async throws {
        // Given
        let viewModel = BlazePaymentMethodsViewModel(siteID: sampleSiteID,
                                                     paymentInfo: samplePaymentInfo,
                                                     selectedPaymentMethodID: "payment-method-1",
                                                     stores: stores) { _ in }

        // When
        viewModel.didSelectPaymentMethod(withID: "payment-method-2")

        // Then
        XCTAssertTrue(viewModel.isDoneButtonEnabled)
    }

    // MARK: `didSelectPaymentMethod`

    func test_didSelectPaymentMethod_updates_selected_payment_method_id() async throws {
        // Given
        let viewModel = BlazePaymentMethodsViewModel(siteID: sampleSiteID,
                                                     paymentInfo: samplePaymentInfo,
                                                     selectedPaymentMethodID: "payment-method-1",
                                                     stores: stores) { _ in }

        // When
        viewModel.didSelectPaymentMethod(withID: "payment-method-2")

        // Then
        XCTAssertEqual(viewModel.selectedPaymentMethodID, "payment-method-2")
    }

    // MARK: Sync payments

    func test_isFetchingPaymentInfo_is_updated_correctly_when_fetching_payment_info() async {
        // Given
        let viewModel = BlazePaymentMethodsViewModel(siteID: sampleSiteID,
                                                     paymentInfo: samplePaymentInfo,
                                                     selectedPaymentMethodID: "payment-method-1",
                                                     stores: stores) { _ in }
        var fetchingStates: [Bool] = []
        subscription = viewModel.$isFetchingPaymentInfo
            .sink { isFetching in
                fetchingStates.append(isFetching)
            }

        // When
        mockPaymentFetch(with: .success(.fake()))
        await viewModel.syncPaymentInfo()

        // Then
        XCTAssertEqual(fetchingStates, [false, true, false])
    }

    func test_shouldDisplayPaymentErrorAlert_is_true_when_fetching_payment_info_fails() async {
        // Given
        let viewModel = BlazePaymentMethodsViewModel(siteID: sampleSiteID,
                                                     paymentInfo: samplePaymentInfo,
                                                     selectedPaymentMethodID: "payment-method-1",
                                                     stores: stores) { _ in }
        XCTAssertFalse(viewModel.shouldDisplayPaymentErrorAlert)

        // When
        mockPaymentFetch(with: .failure(NSError(domain: "Test", code: 500)))
        await viewModel.syncPaymentInfo()

        // Then
        XCTAssertTrue(viewModel.shouldDisplayPaymentErrorAlert)
    }

    func test_syncPaymentInfo_refreshes_payment_methods_on_success() async {
        // Given
        let viewModel = BlazePaymentMethodsViewModel(siteID: sampleSiteID,
                                                     paymentInfo: samplePaymentInfo.copy(savedPaymentMethods: []),
                                                     selectedPaymentMethodID: nil,
                                                     stores: stores) { _ in }
        let paymentMethod = BlazePaymentMethod(id: "test-id",
                                               rawType: "credit-card",
                                               name: "Card ending in 7284",
                                               info: .init(lastDigits: "7284",
                                                           expiring: .fake(),
                                                           type: "Mastercard",
                                                           nickname: nil,
                                                           cardholderName: "Jane Doe"))
        XCTAssertTrue(viewModel.paymentMethods.isEmpty)

        // When
        mockPaymentFetch(with: .success(samplePaymentInfo))
        await viewModel.syncPaymentInfo()

        // Then
        XCTAssertEqual(viewModel.paymentMethods, samplePaymentInfo.savedPaymentMethods)
    }

    // MARK: Save selection
    func test_saveSelection_send_selected_payment_id_via_completion_handler() async throws {
        // Given
        var selectedPaymentID = ""
        let viewModel = BlazePaymentMethodsViewModel(siteID: sampleSiteID,
                                                     paymentInfo: samplePaymentInfo,
                                                     selectedPaymentMethodID: "payment-method-1",
                                                     stores: stores) { id in
            selectedPaymentID = id
        }
        viewModel.didSelectPaymentMethod(withID: "payment-method-2")

        // When
        viewModel.saveSelection()

        // Then
        XCTAssertEqual(selectedPaymentID, "payment-method-2")
    }
}

private extension BlazePaymentMethodsViewModelTests {
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
