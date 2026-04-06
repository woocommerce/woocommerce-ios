import Combine
import Foundation
import Yosemite

final class WooShippingNormalizeAddressViewModel: ObservableObject, Identifiable {
    /// Unique ID for the view model.
    let id = UUID()

    /// The address entered by the merchant.
    let enteredAddress: WooShippingAddress

    /// The suggested (normalized) address.
    let suggestedAddress: WooShippingAddress

    /// The selected address type.
    /// Defaults to the suggested address.
    @Published var selectedAddress: WooShippingSelectedAddressType = .suggested

    /// Closure to perform when the address is confirmed.
    var onConfirm: ((WooShippingAddress) -> Void)?

    init(enteredAddress: WooShippingAddress,
         suggestedAddress: WooShippingAddress,
         onConfirm: ((WooShippingAddress) -> Void)? = nil) {
        self.enteredAddress = enteredAddress
        self.suggestedAddress = suggestedAddress
        self.onConfirm = onConfirm
    }

    /// Confirms the selected address.
    func confirmSelectedAddress() {
        let addressToConfirm = selectedAddress == .entered ? enteredAddress : suggestedAddress
        onConfirm?(addressToConfirm)
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
                           email: "",
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
                           email: "",
                           phone: "",
                           country: "US",
                           state: "NY",
                           address1: "15 ALGONKIN ST",
                           address2: "",
                           city: "TICONDEROGA",
                           postcode: "12883-1487")
    }
}
