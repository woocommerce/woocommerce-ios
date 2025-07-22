import Foundation
import Yosemite

final class WooShippingOriginAddressListViewModel: ObservableObject {
    private(set) var addresses: [WooShippingOriginAddress]
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

    /// Sets the `addressToEdit` property for editing the provided address.
    /// After the address is edited, the updated address is replaced in the list of addresses.
    func editAddress(_ address: WooShippingOriginAddress) {
        addressToEdit = WooShippingEditAddressViewModel(address: address, onAddressEdited: { [weak self] editedAddress in
            guard let self, let index = addresses.firstIndex(where: { $0.id == editedAddress.id }) else {
                return
            }
            addresses.remove(at: index)
            addresses.insert(editedAddress, at: index)
            // If the edited address was the selected address, update the selected address.
            if selectedAddressID == editedAddress.id {
                onSelect?(editedAddress)
            }
            addressToEdit = nil // Dismisses address edit screen
        })
    }
}

// MARK: SwiftUI Previews
extension WooShippingOriginAddressListView {
    static func sampleAddresses() -> [WooShippingOriginAddress] {
        [WooShippingOriginAddress(siteID: 123,
                                  id: "1",
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
         WooShippingOriginAddress(siteID: 123,
                                  id: "2",
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
