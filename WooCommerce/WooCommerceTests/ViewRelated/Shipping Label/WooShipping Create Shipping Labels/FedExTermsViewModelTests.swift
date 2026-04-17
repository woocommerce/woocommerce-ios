import Testing
import Yosemite
@testable import WooCommerce

struct FedExTermsViewModelTests {

    @Test func test_shouldEnableConfirmButton_when_TOS_not_accepted_then_returns_false() {
        // Given
        let viewModel = FedExTermsViewModel(siteID: 123)

        // When / Then
        #expect(viewModel.shouldEnableConfirmButton == false)
    }

    @Test func test_shouldEnableConfirmButton_when_TOS_accepted_then_returns_true() {
        // Given
        let viewModel = FedExTermsViewModel(siteID: 123)

        // When
        viewModel.isTOSAccepted = true

        // Then
        #expect(viewModel.shouldEnableConfirmButton == true)
    }

    @Test func test_displayedOriginAddress_returns_nil() {
        // Given
        let viewModel = FedExTermsViewModel(siteID: 123)

        // Then
        #expect(viewModel.displayedOriginAddress == nil)
    }

    @MainActor
    @Test func test_isConfirming_returns_correct_values() async throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = FedExTermsViewModel(siteID: 123, stores: stores)
        #expect(viewModel.isConfirming == false)

        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case let .acceptFedExTermsOfService(_, completion):
                #expect(viewModel.isConfirming == true)
                completion(.success(true))
            default:
                break
            }
        }

        // When
        let result = try await viewModel.confirmAcceptance()

        // Then
        #expect(viewModel.isConfirming == false)
        #expect(result == true)
    }
}
