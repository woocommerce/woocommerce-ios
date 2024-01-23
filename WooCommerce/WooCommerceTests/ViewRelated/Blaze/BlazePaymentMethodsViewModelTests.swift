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
                                                     stores: stores) { _ in }

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

    // MARK: Save selection

    func test_didSelectPaymentMethod_sends_selected_payment_id_via_completion_handler() async throws {
        // Given
        var selectedPaymentID = ""
        let viewModel = BlazePaymentMethodsViewModel(siteID: sampleSiteID,
                                                     paymentInfo: samplePaymentInfo,
                                                     selectedPaymentMethodID: "payment-method-1",
                                                     stores: stores) { id in
            selectedPaymentID = id
        }
        viewModel.didSelectPaymentMethod(withID: "payment-method-2")

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
