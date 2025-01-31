import XCTest
@testable import WooCommerce
import Yosemite

final class WooShippingNormalizeAddressViewModelTests: XCTestCase {
    private let sampleSiteID: Int64 = 123

    func test_it_inits_with_expected_values() {
        // Given
        let enteredAddress = WooShippingNormalizeAddressViewModel.sampleEnteredAddress
        let suggestedAddress = WooShippingNormalizeAddressViewModel.sampleSuggestedAddress

        // When
        let viewModel = WooShippingNormalizeAddressViewModel(siteID: sampleSiteID,
                                                             originalAddress: WooShippingEditableAddress(originAddress: .fake(),
                                                                                                         destinationAddress: nil,
                                                                                                         addressType: .origin),
                                                             enteredAddress: enteredAddress,
                                                             suggestedAddress: suggestedAddress,
                                                             onConfirm: { _ in })

        // Then
        XCTAssertEqual(viewModel.enteredAddress, enteredAddress)
        XCTAssertEqual(viewModel.suggestedAddress, suggestedAddress)
        XCTAssertEqual(viewModel.selectedAddress, .suggested)
    }

    @MainActor
    func test_confirmSelectedAddress_for_origin_address_calls_onConfirm_with_expected_address() async {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case let .updateOriginAddress(_, _, _, completion):
                completion(.success(WooShippingOriginAddressUpdate(address: .fake(), isVerified: true)))
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }
        var confirmedAddress: WooShippingEditableAddress?
        let viewModel = WooShippingNormalizeAddressViewModel(siteID: sampleSiteID,
                                                             originalAddress: WooShippingEditableAddress(originAddress: .fake(),
                                                                                                         destinationAddress: nil,
                                                                                                         addressType: .origin),
                                                             enteredAddress: WooShippingNormalizeAddressViewModel.sampleEnteredAddress,
                                                             suggestedAddress: WooShippingNormalizeAddressViewModel.sampleSuggestedAddress,
                                                             stores: stores,
                                                             onConfirm: { address in
            confirmedAddress = address
        })

        // When
        viewModel.selectedAddress = .entered
        await viewModel.confirmSelectedAddress()

        // Then
        let expectedAddress = WooShippingEditableAddress(originAddress: .fake(), destinationAddress: nil, addressType: .origin)
        XCTAssertEqual(confirmedAddress, expectedAddress)
    }

    @MainActor
    func test_isRemotelyUpdating_set_during_and_after_remote_origin_address_update() async {
        // Given
        var isRemotelyUpdatingDuringRemoteAction = false
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = WooShippingNormalizeAddressViewModel(siteID: sampleSiteID,
                                                             originalAddress: WooShippingEditableAddress(originAddress: .fake(),
                                                                                                         destinationAddress: nil,
                                                                                                         addressType: .origin),
                                                             enteredAddress: WooShippingNormalizeAddressViewModel.sampleEnteredAddress,
                                                             suggestedAddress: WooShippingNormalizeAddressViewModel.sampleSuggestedAddress,
                                                             stores: stores,
                                                             onConfirm: { _ in })
        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            if case let .updateOriginAddress(_, _, _, completion) = action {
                isRemotelyUpdatingDuringRemoteAction = viewModel.isRemotelyUpdating
                completion(.success(WooShippingOriginAddressUpdate(address: .fake(), isVerified: true)))
            }
        }

        // When
        await viewModel.confirmSelectedAddress()

        // Then
        XCTAssertTrue(isRemotelyUpdatingDuringRemoteAction)
        XCTAssertFalse(viewModel.isRemotelyUpdating)
    }

    @MainActor
    func test_confirmSelectedAddress_sends_expected_origin_address_to_remote() async {
        // Given
        let originAddress = WooShippingOriginAddress.fake().copy(id: "origin", company: "COMPANY")
        let suggestedAddress = WooShippingNormalizeAddressViewModel.sampleSuggestedAddress
        var receivedAddress: WooShippingOriginAddress?
        let stores = MockStoresManager(sessionManager: .testingInstance)
        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            if case let .updateOriginAddress(_, address, _, completion) = action {
                receivedAddress = address
                completion(.success(WooShippingOriginAddressUpdate(address: address, isVerified: true)))
            }
        }
        let viewModel = WooShippingNormalizeAddressViewModel(siteID: sampleSiteID,
                                                             originalAddress: WooShippingEditableAddress(originAddress: originAddress,
                                                                                                         destinationAddress: nil,
                                                                                                         addressType: .origin),
                                                             enteredAddress: WooShippingNormalizeAddressViewModel.sampleEnteredAddress,
                                                             suggestedAddress: suggestedAddress,
                                                             stores: stores,
                                                             onConfirm: { _ in })

        // When
        await viewModel.confirmSelectedAddress()

        // Then
        let expectedAddress = WooShippingOriginAddress(id: originAddress.id,
                                                       company: suggestedAddress.company,
                                                       address1: suggestedAddress.address1,
                                                       address2: suggestedAddress.address2,
                                                       city: suggestedAddress.city,
                                                       state: suggestedAddress.state,
                                                       postcode: suggestedAddress.postcode,
                                                       country: suggestedAddress.country,
                                                       phone: originAddress.phone,
                                                       firstName: suggestedAddress.name,
                                                       lastName: "",
                                                       email: originAddress.email,
                                                       defaultAddress: originAddress.defaultAddress,
                                                       isVerified: originAddress.isVerified)
        XCTAssertEqual(receivedAddress, expectedAddress)
    }
}
