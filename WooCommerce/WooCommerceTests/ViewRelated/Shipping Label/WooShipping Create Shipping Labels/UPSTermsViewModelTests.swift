import Testing
import Yosemite
@testable import WooCommerce

struct UPSTermsViewModelTests {

    @Test func displayedOriginAddress_returns_correct_value() async throws {
        // Given
        let originAddress = WooShippingAddress(company: "A8C",
                                               name: "Teddy Bear",
                                               email: nil,
                                               phone: "0985728394",
                                               country: "US",
                                               state: "New York",
                                               address1: "1 E 35th St",
                                               address2: "",
                                               city: "New York",
                                               postcode: "10028")

        // When
        let viewModel = UPSTermsViewModel(siteID: 123, originAddress: originAddress)

        // Then
        #expect(viewModel.displayedOriginAddress == "1 E 35th St, New York New York 10028, US")
    }

    @Test(arguments: [
        (false, false, false),
        (true, false, false),
        (true, true, false),
        (false, true, false),
        (false, true, true),
        (false, false, true)
    ])
    func confirm_button_is_not_enabled_when_any_of_the_agreements_are_not_accepted(isTOSAccepted: Bool,
                                                                                   isProhibitedItemsAccepted: Bool,
                                                                                   isTechAgreementAccepted: Bool) {
        // Given
        let originAddress = WooShippingAddress(company: "A8C",
                                               name: "Teddy Bear",
                                               email: nil,
                                               phone: "0985728394",
                                               country: "US",
                                               state: "New York",
                                               address1: "1 E 35th St",
                                               address2: "",
                                               city: "New York",
                                               postcode: "10028")
        let viewModel = UPSTermsViewModel(siteID: 123, originAddress: originAddress)

        // When
        viewModel.isTOSAccepted = isTOSAccepted
        viewModel.isProhibitedItemsAccepted = isProhibitedItemsAccepted
        viewModel.isTechnologyAgreementAccepted = isTechAgreementAccepted

        // Then
        #expect(viewModel.shouldEnableConfirmButton == false)
    }

    @Test func confirm_button_is_enabled_when_all_agreements_are_accepted() {
        // Given
        let originAddress = WooShippingAddress(company: "A8C",
                                               name: "Teddy Bear",
                                               email: nil,
                                               phone: "0985728394",
                                               country: "US",
                                               state: "New York",
                                               address1: "1 E 35th St",
                                               address2: "",
                                               city: "New York",
                                               postcode: "10028")
        let viewModel = UPSTermsViewModel(siteID: 123, originAddress: originAddress)

        // When
        viewModel.isTOSAccepted = true
        viewModel.isProhibitedItemsAccepted = true
        viewModel.isTechnologyAgreementAccepted = true

        // Then
        #expect(viewModel.shouldEnableConfirmButton == true)
    }

    @MainActor
    @Test func isConfirming_returns_correct_values() async throws {
        // Given
        let originAddress = WooShippingAddress(company: "A8C",
                                               name: "Teddy Bear",
                                               email: nil,
                                               phone: "0985728394",
                                               country: "US",
                                               state: "New York",
                                               address1: "1 E 35th St",
                                               address2: "",
                                               city: "New York",
                                               postcode: "10028")

        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = UPSTermsViewModel(siteID: 123, originAddress: originAddress, stores: stores)
        #expect(viewModel.isConfirming == false)

        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case let .acceptUPSTermsOfService(_, _, completion):
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
