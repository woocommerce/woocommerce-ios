import Yosemite
import Combine

final class EditAddressFormViewModel: ObservableObject {

    /// Current site ID
    ///
    private let siteID: Int64

    init(siteID: Int64, address: Address?) {
        self.siteID = siteID
        self.originalAddress = address ?? .empty
        updateFieldsWithOriginalAddress()
        bindNavigationTrailingItemPublisher()
    }

    /// Original `Address` model.
    ///
    private let originalAddress: Address

    /// Tracks if a network request is being performed.
    ///
    private let performingNetworkRequest: CurrentValueSubject<Bool, Never> = .init(false)

    // MARK: Form Fields

    /// Address form fields
    ///
    @Published var fields = FormFields()

    // MARK: Navigation and utility

    /// Active navigation bar trailing item.
    /// Defaults to a disabled done button.
    ///
    @Published private(set) var navigationTrailingItem: NavigationItem = .done(enabled: false)

    /// Creates a view model to be used when selecting a country
    ///
    func createCountryViewModel() -> CountrySelectorViewModel {
        CountrySelectorViewModel(siteID: siteID)
    }

    /// Update the address remotely and invoke a completion block when finished
    ///
    func updateRemoteAddress(onFinish: @escaping (Bool) -> Void) {
        // TODO: perform network request
        // TODO: add success/failure notice

        // To corroborate that the fields are getting updated
        print("Address to update: \(fields)")

        performingNetworkRequest.send(true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.performingNetworkRequest.send(false)
            onFinish(true)
        }
    }
}

extension EditAddressFormViewModel {
    /// Representation of possible navigation bar trailing buttons
    ///
    enum NavigationItem: Equatable {
        case done(enabled: Bool)
        case loading
    }
}

private extension EditAddressFormViewModel {
    func updateFieldsWithOriginalAddress() {
        fields.update(from: originalAddress)
    }

    /// Calculates what navigation trailing item should be shown depending on our internal state.
    ///
    func bindNavigationTrailingItemPublisher() {
        Publishers.CombineLatest($fields, performingNetworkRequest)
            .map { [originalAddress] fields, performingNetworkRequest -> NavigationItem in
                guard !performingNetworkRequest else {
                    return .loading
                }
                return .done(enabled: originalAddress != fields.toAddress())
            }
            .assign(to: &$navigationTrailingItem)
    }
}


extension EditAddressFormViewModel {
    /// Type to hold values from all the form fields 
    ///
    struct FormFields {
        // MARK: User Fields
        var firstName: String = ""
        var lastName: String = ""
        var email: String = ""
        var phone: String = ""

        // MARK: Address Fields

        var company: String = ""
        var address1: String = ""
        var address2: String = ""
        var city: String = ""
        var postcode: String = ""
        var country: String = ""
        var state: String = ""

        mutating func update(from address: Address) {
            firstName = address.firstName
            lastName = address.lastName
            email = address.email ?? ""
            phone = address.phone ?? ""

            company = address.company ?? ""
            address1 = address.address1
            address2 = address.address2 ?? ""
            city = address.city
            postcode = address.postcode
            country = address.country
            state = address.state
        }

        func toAddress() -> Address {
            Address(firstName: firstName,
                    lastName: lastName,
                    company: company,
                    address1: address1,
                    address2: address2,
                    city: city,
                    state: state,
                    postcode: postcode,
                    country: country,
                    phone: phone,
                    email: email)
        }
    }
}
