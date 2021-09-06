import Yosemite

final class EditAddressFormViewModel: ObservableObject {

    init(address: Address?) {
        self.originalAddress = address
        updateFieldsWithOriginalAddress()
    }

    /// Original `Address` model.
    ///
    private let originalAddress: Address?

    // MARK: User Fields

    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var email: String = ""
    @Published var phone: String = ""

    // MARK: Address Fields

    @Published var company: String = ""
    @Published var address1: String = ""
    @Published var address2: String = ""
    @Published var city: String = ""
    @Published var postcode: String = ""

    // MARK: Navigation and utility

    /// Set it to `true` to present the country selector.
    ///
    @Published var showCountrySelector: Bool = false

    /// Return `true` if the done button should be enabled.
    ///
    var isDoneButtonEnabled: Bool {
        return false
    }
}

private extension EditAddressFormViewModel {
    func updateFieldsWithOriginalAddress() {
        guard let originalAddress = originalAddress else { return }

        firstName = originalAddress.firstName
        lastName = originalAddress.lastName
        email = originalAddress.email ?? ""
        phone = originalAddress.phone ?? ""

        company = originalAddress.company ?? ""
        address1 = originalAddress.address1
        address2 = originalAddress.address2 ?? ""
        city = originalAddress.city
        postcode = originalAddress.postcode
    }
}
