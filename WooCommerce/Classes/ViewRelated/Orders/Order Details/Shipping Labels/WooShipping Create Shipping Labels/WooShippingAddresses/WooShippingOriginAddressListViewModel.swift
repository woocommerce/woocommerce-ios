import Foundation
import Yosemite

final class WooShippingOriginAddressListViewModel: ObservableObject {
    let addresses: [WooShippingOriginAddress]
    @Published private(set) var selectedAddressID: String?

    /// View model for address to edit.
    /// Setting this property will navigate to the address edit screen.
    @Published var addressToEdit: WooShippingEditAddressViewModel?

    /// Closure (set externally) called when an address is selected.
    var onSelect: ((WooShippingOriginAddress) -> Void)?

    init(addresses: [WooShippingOriginAddress],
         selectedAddressID: String? = nil) {
        self.addresses = addresses
        self.selectedAddressID = selectedAddressID
    }

    /// Whether the provided address is selected.
    func isSelected(_ address: WooShippingOriginAddress) -> Bool {
        selectedAddressID == address.id
    }

    /// Selects the provided address to use as the origin address for the shipping label.
    func select(_ address: WooShippingOriginAddress) {
        guard addresses.contains(address) else {
            return
        }
        selectedAddressID = address.id
        onSelect?(address)
    }

    func editAddress(_ address: WooShippingOriginAddress) {
        addressToEdit = WooShippingEditAddressViewModel(address: address)
    }
}

// MARK: SwiftUI Previews
extension WooShippingOriginAddressListView {
    static func sampleAddresses() -> [WooShippingOriginAddress] {
        [WooShippingOriginAddress(id: "1",
                                  company: "HEADQUARTERS",
                                  address1: "417 MONTGOMERY ST",
                                  address2: "",
                                  city: "SAN FRANCISCO",
                                  state: "CA",
                                  postcode: "94104-1129",
                                  country: "US",
                                  phone: "",
                                  firstName: "GENERAL",
                                  lastName: "MANAGER",
                                  email: "",
                                  defaultAddress: true,
                                  isVerified: true),
         WooShippingOriginAddress(id: "2",
                                  company: "WAREHOUSE",
                                  address1: "15 ALGONKIN ST",
                                  address2: "",
                                  city: "TICONDEROGA",
                                  state: "NY",
                                  postcode: "12883-1487",
                                  country: "US",
                                  phone: "",
                                  firstName: "",
                                  lastName: "",
                                  email: "",
                                  defaultAddress: false,
                                  isVerified: true)]
    }
}
