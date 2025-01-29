import Yosemite

final class WooShippingNormalizeAddressViewModel: ObservableObject {
    /// The address entered by the merchant.
    let enteredAddress: WooShippingAddress

    /// The suggested (normalized) address.
    let suggestedAddress: WooShippingAddress

    /// The selected address type.
    /// Defaults to the suggested address.
    @Published private(set) var selectedAddress: WooShippingSelectedAddressType = .suggested

    init(enteredAddress: WooShippingAddress, suggestedAddress: WooShippingAddress) {
        self.enteredAddress = enteredAddress
        self.suggestedAddress = suggestedAddress
    }
}

/// Represents which address the merchant has selected for the shipping label.
enum WooShippingSelectedAddressType {
    case entered
    case suggested
}

// MARK: - Sample Data for SwiftUI Previews
#if DEBUG
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
#endif
