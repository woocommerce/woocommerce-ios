import Combine
import Yosemite
import Experiments
import class WordPressShared.EmailFormatValidator
import protocol Storage.StorageManagerType

/// Protocol to describe viewmodel of editable address
///
protocol AddressFormViewModelProtocol: ObservableObject {

    /// Site ID
    ///
    var siteID: Int64 { get }

    /// Address form fields
    ///
    var fields: AddressFormFields { get set }

    /// Secondary address form fields
    ///
    var secondaryFields: AddressFormFields { get set }

    /// Define if address form should be expanded (show second set of fields for different address)
    ///
    var showDifferentAddressForm: Bool { get set }

    /// Active navigation bar trailing item.
    /// Defaults to a disabled done button.
    ///
    var navigationTrailingItem: AddressFormNavigationItem { get }

    /// Trigger to perform any one time setups.
    ///
    var onLoadTrigger: PassthroughSubject<Void, Never> { get }

    /// Define if the view should show a search button to look for the addresses.
    ///
    var showSearchButton: Bool { get }

    /// Define if the view should show placeholders instead of the real elements.
    ///
    var showPlaceholders: Bool { get }

    /// Defines if the state field should be defined as a list selector.
    ///
    var showStateFieldAsSelector: Bool { get }

    /// Defines if secondary state field should be defined as a list selector.
    ///
    var showSecondaryStateFieldAsSelector: Bool { get }

    /// Defines if the email field should be shown
    ///
    var showEmailField: Bool { get }

    /// Defines if the phone country code field should be shown
    ///
    var showPhoneCountryCodeField: Bool { get }

    /// Defines navbar title
    ///
    var viewTitle: String { get }

    /// Defines address section title
    ///
    var sectionTitle: String { get }

    /// Defines address section title for second set of fields
    ///
    var secondarySectionTitle: String { get }

    /// Defines if "use as billing/shipping" toggle should be displayed.
    ///
    var showAlternativeUsageToggle: Bool { get }

    /// Defines "use as billing/shipping" toggle title
    ///
    var alternativeUsageToggleTitle: String? { get }

    /// Defines if "add different address" toggle should be displayed.
    ///
    var showDifferentAddressToggle: Bool { get }

    /// Defines "add different address" toggle title
    ///
    var differentAddressToggleTitle: String? { get }

    /// Defines the active notice to show.
    ///
    var notice: Notice? { get set }

    /// Save the address and invoke a completion block when finished
    ///
    func saveAddress(onFinish: @escaping (Bool) -> Void)

    /// Track the flow cancel scenario.
    ///
    func userDidCancelFlow()

    /// Creates a view model to be used when selecting a country for primary fields
    ///
    func createCountryViewModel() -> CountrySelectorViewModel

    /// Creates a view model to be used when selecting a state for primary fields
    ///
    func createStateViewModel() -> StateSelectorViewModel

    /// Creates a view model to be used when selecting a country for secondary fields
    ///
    func createSecondaryCountryViewModel() -> CountrySelectorViewModel

    /// Creates a view model to be used when selecting a state for secondary fields
    ///
    func createSecondaryStateViewModel() -> StateSelectorViewModel

    /// Triggers the logic to fill Customer Order details when a Customer is selected
    ///
    func customerSelectedFromSearch(customer: Customer)
}

/// Type to hold values from all the form fields
///
struct AddressFormFields {
    // MARK: User Fields
    var firstName: String = ""
    var lastName: String = ""
    var email: String = ""
    var phone: String = ""
    // Not available in `Address` conversion, currently only available in domain contact info form.
    var phoneCountryCode: String = ""

    // MARK: Address Fields
    var company: String = ""
    var address1: String = ""
    var address2: String = ""
    var city: String = ""
    var postcode: String = ""

    var country: String = ""
    var state: String = ""

    var useAsToggle: Bool = false

    init() {}

    init(with address: Address) {
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

    func toAddress() -> Yosemite.Address {
        Address(firstName: firstName,
                lastName: lastName,
                company: company,
                address1: address1,
                address2: address2,
                city: city,
                state: selectedState?.code ?? state,
                postcode: postcode,
                country: selectedCountry?.code ?? country,
                phone: phone,
                email: email)
    }

    // MARK: Country & state

    /// Current selected country.
    ///
    var selectedCountry: Yosemite.Country? {
        didSet {
            self.country = selectedCountry?.name ?? ""

            // When a country is selected, check if the new country has a state list.
            // If it has, clear the selected state and its name in fields.
            // If it doesn't only clear the selected state.
            if selectedCountry?.states.isEmpty == false {
                self.state = ""
            }
            self.selectedState = nil
        }
    }

    /// Current selected state.
    ///
    var selectedState: Yosemite.StateOfACountry? {
        didSet {
            if let selectedState = selectedState {
                self.state = selectedState.name
            }
        }
    }

    /// Set initial values from Address using the stored countries to compute the current selected country & state.
    ///
    mutating func refreshCountryAndStateObjects(with allCountries: [Country]) {
        // Do not overwrite any prefilled/selected items
        guard selectedCountry == nil, selectedState == nil else {
            return
        }

        let initialStateValue = state // storing initial state value because it will be cleared by selectedCountry setter
        selectedCountry = allCountries.first { $0.code == country }
        selectedState = selectedCountry?.states.first { $0.code == initialStateValue }
    }
}

/// Representation of possible navigation bar trailing buttons
///
enum AddressFormNavigationItem: Equatable {
    case done(enabled: Bool)
    case loading
}
