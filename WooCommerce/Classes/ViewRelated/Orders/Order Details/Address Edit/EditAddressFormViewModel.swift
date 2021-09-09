import Yosemite
import Combine

final class EditAddressFormViewModel: ObservableObject {

    /// Current site ID
    ///
    private let siteID: Int64

    init(siteID: Int64, address: Address?) {
        self.siteID = siteID
        self.originalAddress = address ?? .empty
        self.updatedAddress = address ?? .empty
        updateFieldsWithOriginalAddress()
        bindAllFieldsToUpdatedAddressPublisher()
    }

    /// Original `Address` model.
    ///
    private let originalAddress: Address

    /// Updated `Address` model.
    ///
    @Published var updatedAddress: Address

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

    /// Return `true` if the done button should be enabled.
    ///
    var isDoneButtonEnabled: Bool {
        return originalAddress != updatedAddress
    }

    /// Creates a view model to be used when selecting a country
    ///
    func createCountryViewModel() -> CountrySelectorViewModel {
        CountrySelectorViewModel(siteID: siteID)
    }
}

private extension EditAddressFormViewModel {
    func updateFieldsWithOriginalAddress() {
        firstName = originalAddress.firstName
        lastName = originalAddress.lastName
        email = originalAddress.email ?? ""
        phone = originalAddress.phone ?? ""

        company = originalAddress.company ?? ""
        address1 = originalAddress.address1
        address2 = originalAddress.address2 ?? ""
        city = originalAddress.city
        postcode = originalAddress.postcode

        // TODO: Add country and state init
    }

    /// Updates `updatedAddress` after any field change.
    ///
    func bindAllFieldsToUpdatedAddressPublisher() {
        Publishers.CombineLatest3(Publishers.CombineLatest4($firstName,
                                                            $lastName,
                                                            $email,
                                                            $phone),
                                  Publishers.CombineLatest3($company,
                                                            $address1,
                                                            $address2),
                                  Publishers.CombineLatest($city,
                                                           $postcode))
            .map { [originalAddress] firstSection, secondSection, thirdSection -> Address in
                Address(firstName: firstSection.0,
                        lastName: firstSection.1,
                        company: secondSection.0,
                        address1: secondSection.1,
                        address2: secondSection.2,
                        city: thirdSection.0,
                        state: originalAddress.state, // TODO: bind to local value
                        postcode: thirdSection.1,
                        country: originalAddress.country, // TODO: bind to local value
                        phone: firstSection.3,
                        email: firstSection.2)
            }
            .assign(to: &$updatedAddress)
    }
}
