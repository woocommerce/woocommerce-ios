import Yosemite

final class WooShippingNormalizeAddressViewModel: ObservableObject, Identifiable {
    private let siteID: Int64
    private let stores: StoresManager

    /// Original address to update.
    private let originalAddress: WooShippingEditableAddress

    /// Unique ID for the view model.
    let id = UUID()

    /// The new address entered by the merchant.
    let enteredAddress: WooShippingAddress

    /// The suggested (normalized) new address.
    let suggestedAddress: WooShippingAddress

    /// The selected address type.
    /// Defaults to the suggested address.
    @Published var selectedAddress: WooShippingSelectedAddressType = .suggested

    /// Closure to perform when the address is confirmed.
    var onConfirm: ((WooShippingEditableAddress) -> Void)?

    /// Whether the address is being remotely updated.
    /// This property is used to show a loading indicator while the remote update is in progress.
    @Published private(set) var isRemotelyUpdating: Bool = false

    init(siteID: Int64,
         originalAddress: WooShippingEditableAddress,
         enteredAddress: WooShippingAddress,
         suggestedAddress: WooShippingAddress,
         stores: StoresManager = ServiceLocator.stores,
         onConfirm: ((WooShippingEditableAddress) -> Void)? = nil) {
        self.siteID = siteID
        self.stores = stores
        self.originalAddress = originalAddress
        self.enteredAddress = enteredAddress
        self.suggestedAddress = suggestedAddress
        self.onConfirm = onConfirm
    }

    /// Confirms the selected address.
    @MainActor
    func confirmSelectedAddress() async throws {
        let addressToConfirm = selectedAddress == .entered ? enteredAddress : suggestedAddress
        do {
            if let originAddress = originalAddress.originAddress {
                let updatedOriginAddress = try await updateOriginAddress(originAddress, with: addressToConfirm)
                let updatedEditableAddress = WooShippingEditableAddress(originAddress: updatedOriginAddress,
                                                                        destinationAddress: originalAddress.destinationAddress,
                                                                        addressType: originalAddress.addressType)
                onConfirm?(updatedEditableAddress)
            }
        } catch {
            DDLogError("⛔️ Error updating origin address for Woo Shipping label: \(error)")
            throw error
        }
    }
}

// MARK: Remote
private extension WooShippingNormalizeAddressViewModel {
    /// Updates an origin address remotely.
    @MainActor
    func updateOriginAddress(_ originAddress: WooShippingOriginAddress, with address: WooShippingAddress) async throws -> WooShippingOriginAddress {
        let updatedAddress = originAddress.copy(company: address.company,
                                                address1: address.address1,
                                                address2: address.address2,
                                                city: address.city,
                                                state: address.state,
                                                postcode: address.postcode,
                                                country: address.country,
                                                phone: address.phone,
                                                firstName: address.name)
        return try await withCheckedThrowingContinuation { continuation in
            isRemotelyUpdating = true
            let action = WooShippingAction.updateOriginAddress(siteID: siteID,
                                                               address: updatedAddress,
                                                               isVerified: updatedAddress.isVerified) { [weak self] result in
                guard let self else { return }
                switch result {
                case let .success(result):
                    continuation.resume(returning: result.address)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
                isRemotelyUpdating = false
            }
            stores.dispatch(action)
        }
    }
}

/// Represents which address the merchant has selected for the shipping label.
enum WooShippingSelectedAddressType {
    case entered
    case suggested
}

// MARK: - Sample Data for SwiftUI Previews
extension WooShippingNormalizeAddressViewModel {
    static var sampleEnteredAddress: WooShippingAddress {
        WooShippingAddress(company: "",
                           name: "",
                           phone: "",
                           country: "US",
                           state: "NY",
                           address1: "15 Algonkin St",
                           address2: "",
                           city: "Ticonderogaa",
                           postcode: "12883-1487")
    }

    static var sampleSuggestedAddress: WooShippingAddress {
        WooShippingAddress(company: "",
                           name: "",
                           phone: "",
                           country: "US",
                           state: "NY",
                           address1: "15 ALGONKIN ST",
                           address2: "",
                           city: "TICONDEROGA",
                           postcode: "12883-1487")
    }
}
