import Combine
import Yosemite
import class WordPressShared.EmailFormatValidator
import protocol Storage.StorageManagerType

/// Protocol to describe viewmodel of editable address
///
protocol AddressFormViewModelProtocol: ObservableObject {

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
}

/// Type to hold values from all the form fields
///
struct AddressFormFields {
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

/// Parent class for AddressFormViewModelProtocol implementations. Holds shared sync/management logic.
/// Not to be used on its own, so it doesn't conform to AddressFormViewModelProtocol.
///
open class AddressFormViewModel: ObservableObject {
    /// ResultsController for stored countries.
    ///
    private lazy var countriesResultsController: ResultsController<StorageCountry> = {
        let countriesDescriptor = NSSortDescriptor(key: "name", ascending: true)
        return ResultsController<StorageCountry>(storageManager: storageManager, sortedBy: [countriesDescriptor])
    }()

    /// Array for all stored countries.
    ///
    private var allCountries: [Country] {
        countriesResultsController.fetchedObjects
    }

    /// Trigger to sync countries.
    ///
    private let syncCountriesTrigger = PassthroughSubject<Void, Never>()

    /// Storage to fetch countries
    ///
    private let storageManager: StorageManagerType

    /// Stores to sync countries
    ///
    let stores: StoresManager

    /// Analytics center.
    ///
    let analytics: Analytics

    /// Store for publishers subscriptions
    ///
    private var subscriptions = Set<AnyCancellable>()

    init(siteID: Int64,
         address: Address,
         secondaryAddress: Address? = nil,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        self.siteID = siteID

        self.originalAddress = address
        self.fields = .init(with: originalAddress)

        self.secondaryOriginalAddress = secondaryAddress ?? .empty
        self.secondaryFields = .init(with: secondaryOriginalAddress)

        self.storageManager = storageManager
        self.stores = stores
        self.analytics = analytics

        // Listen only to the first emitted event.
        onLoadTrigger.first().sink { [weak self] in
            guard let self = self else { return }
            self.bindSyncTrigger()
            self.bindNavigationTrailingItemPublisher()

            self.fetchStoredCountriesAndTriggerSyncIfNeeded()
            self.refreshCountryAndStateObjects()

            self.trackOnLoad()
        }.store(in: &subscriptions)
    }

    private let siteID: Int64

    /// Original `Address` model.
    ///
    private let originalAddress: Address

    /// Secondary original `Address` model.
    ///
    private let secondaryOriginalAddress: Address

    /// Address form fields
    ///
    @Published var fields: AddressFormFields

    /// Secondary address form fields
    ///
    @Published var secondaryFields: AddressFormFields = .init()

    /// Define if address form should be expanded (show second set of fields for different address)
    ///
    @Published var showDifferentAddressForm: Bool = false

    /// Trigger to perform any one time setups.
    ///
    let onLoadTrigger: PassthroughSubject<Void, Never> = PassthroughSubject()

    /// Tracks if a network request is being performed.
    ///
    let performingNetworkRequest: CurrentValueSubject<Bool, Never> = .init(false)

    /// Active navigation bar trailing item.
    /// Defaults to a disabled done button.
    ///
    @Published private(set) var navigationTrailingItem: AddressFormNavigationItem = .done(enabled: false)

    /// Define if the view should show placeholders instead of the real elements.
    ///
    @Published private(set) var showPlaceholders: Bool = false

    /// Defines the current notice that should be shown.
    /// Defaults to `nil`.
    ///
    @Published var notice: Notice?

    /// Defines if the state field should be defined as a list selector.
    ///
    var showStateFieldAsSelector: Bool {
        fields.selectedCountry?.states.isNotEmpty ?? false
    }

    /// Defines if the state field should be defined as a list selector.
    ///
    var showSecondaryStateFieldAsSelector: Bool {
        secondaryFields.selectedCountry?.states.isNotEmpty ?? false
    }

    /// Creates a view model to be used when selecting a country for primary fields
    ///
    func createCountryViewModel() -> CountrySelectorViewModel {
        let selectedCountryBinding = Binding(
            get: { self.fields.selectedCountry },
            set: { self.fields.selectedCountry = $0 }
        )
        return CountrySelectorViewModel(countries: allCountries, selected: selectedCountryBinding)
    }

    /// Creates a view model to be used when selecting a state for primary fields
    ///
    func createStateViewModel() -> StateSelectorViewModel {
        let selectedStateBinding = Binding(
            get: { self.fields.selectedState },
            set: { self.fields.selectedState = $0 }
        )

        // Sort states from the selected country
        let states = fields.selectedCountry?.states.sorted { $0.name < $1.name } ?? []
        return StateSelectorViewModel(states: states, selected: selectedStateBinding)
    }

    /// Creates a view model to be used when selecting a country for secondary fields
    ///
    func createSecondaryCountryViewModel() -> CountrySelectorViewModel {
        let selectedCountryBinding = Binding(
            get: { self.secondaryFields.selectedCountry },
            set: { self.secondaryFields.selectedCountry = $0 }
        )
        return CountrySelectorViewModel(countries: allCountries, selected: selectedCountryBinding)
    }

    /// Creates a view model to be used when selecting a state for secondary fields
    ///
    func createSecondaryStateViewModel() -> StateSelectorViewModel {
        let selectedStateBinding = Binding(
            get: { self.secondaryFields.selectedState },
            set: { self.secondaryFields.selectedState = $0 }
        )

        // Sort states from the selected country
        let states = secondaryFields.selectedCountry?.states.sorted { $0.name < $1.name } ?? []
        return StateSelectorViewModel(states: states, selected: selectedStateBinding)
    }

    /// Track the flow start. Override in subclass.
    ///
    func trackOnLoad() {
        // override in subclass
    }

    /// Returns `true` if the fields contains a valid email or if there is no email to validate. `False` otherwise.
    ///
    func validateEmail() -> Bool {
        let primaryEmailIsValid = fields.email.isEmpty || EmailFormatValidator.validate(string: fields.email)
        let secondaryEmailIsValid = secondaryFields.email.isEmpty || EmailFormatValidator.validate(string: fields.email)
        return primaryEmailIsValid && secondaryEmailIsValid
    }
}

extension AddressFormViewModel {

    /// Representation of possible errors that can happen
    enum EditAddressError: LocalizedError {
        case unableToLoadCountries
        case unableToUpdateAddress

        var errorDescription: String? {
            switch self {
            case .unableToLoadCountries:
                return NSLocalizedString("Unable to fetch country information, please try again later.",
                                         comment: "Error notice when we fail to load country information in the edit address screen.")
            case .unableToUpdateAddress:
                return NSLocalizedString("Unable to update address.",
                                         comment: "Error notice title when we fail to update an address in the edit address screen.")
            }
        }

        var recoverySuggestion: String? {
            switch self {
            case .unableToLoadCountries:
                return nil
            case .unableToUpdateAddress:
                return NSLocalizedString("Please make sure you are running the latest version of WooCommerce and try again later.",
                                         comment: "Error notice recovery suggestion when we fail to update an address in the edit address screen.")
            }
        }
    }

    enum Localization {
        static let invalidEmail = NSLocalizedString("Please enter a valid email address.", comment: "Notice text when the merchant enters an invalid email")
    }

    /// Creates address form general notices.
    ///
    enum NoticeFactory {
        /// Creates an error notice based on the provided edit address error.
        ///
        static func createErrorNotice(from error: EditAddressError) -> Notice {
            Notice(title: error.errorDescription ?? "", message: error.recoverySuggestion, feedbackType: .error)
        }

        /// Creates an error notice indicating that the email address is invalid.
        ///
        static func createInvalidEmailNotice() -> Notice {
            .init(title: Localization.invalidEmail, feedbackType: .error)
        }
    }
}

private extension AddressFormViewModel {

    /// Set initial values from Address using the stored countries to compute the current selected country & state.
    ///
    func refreshCountryAndStateObjects() {
        fields.refreshCountryAndStateObjects(with: allCountries)
        secondaryFields.refreshCountryAndStateObjects(with: allCountries)
    }

    /// Calculates what navigation trailing item should be shown depending on our internal state.
    ///
    func bindNavigationTrailingItemPublisher() {
        Publishers.CombineLatest4($fields, $secondaryFields, $showDifferentAddressForm, performingNetworkRequest)
            .map { [originalAddress, secondaryOriginalAddress]
                fields, secondaryFields, showDifferentAddressForm, performingNetworkRequest -> AddressFormNavigationItem in
                guard !performingNetworkRequest else {
                    return .loading
                }

                guard !fields.useAsToggle else {
                    return .done(enabled: true)
                }

                let addressesAreDifferentButSecondAddressSwitchIsDisabled = secondaryOriginalAddress != .empty &&
                originalAddress != secondaryOriginalAddress &&
                !showDifferentAddressForm

                return .done(enabled: addressesAreDifferentButSecondAddressSwitchIsDisabled ||
                             originalAddress != fields.toAddress() ||
                             secondaryOriginalAddress != secondaryFields.toAddress())
            }
            .assign(to: &$navigationTrailingItem)
    }

    /// Fetches countries from storage, If there are no stored countries, trigger a sync request.
    ///
    func fetchStoredCountriesAndTriggerSyncIfNeeded() {
        // Initial fetch
        try? countriesResultsController.performFetch()

        // Updates the initial fields when/if the data store changes(after sync).
        countriesResultsController.onDidChangeContent = { [weak self] in
            guard let self = self else { return }

            self.refreshCountryAndStateObjects()
        }

        // Trigger a sync request if there are no countries.
        guard !countriesResultsController.isEmpty else {
            return syncCountriesTrigger.send()
        }
    }

    /// Sync countries when requested. Defines the `showPlaceholderState` value depending if countries are being synced or not.
    ///
    func bindSyncTrigger() {

        // Sends an error notice presentation request and hides the publisher error.
        let syncCountries = makeSyncCountriesFuture()
            .catch { [weak self] error -> AnyPublisher<Void, Never> in
                DDLogError("⛔️ Failed to load countries with: \(error)")
                self?.notice = NoticeFactory.createErrorNotice(from: error)
                return Just(()).eraseToAnyPublisher()
            }

        // Perform `syncCountries` when a sync trigger is requested.
        syncCountriesTrigger
            .handleEvents(receiveOutput: { // Set `showPlaceholders` to `true` before initiating sync.
                self.showPlaceholders = true // I could not find a way to assign this using combine operators. :-(
            })
            .map { // Sync countries
                syncCountries
            }
            .switchToLatest()
            .map { _ in // Set `showPlaceholders` to `false` after sync is done.
                false
            }
            .assign(to: &$showPlaceholders)
    }

    /// Creates a publisher that syncs countries into our storage layer.
    ///
    func makeSyncCountriesFuture() -> AnyPublisher<Void, EditAddressError> {
        Future<Void, EditAddressError> { [weak self] promise in
            guard let self = self else { return }

            let action = DataAction.synchronizeCountries(siteID: self.siteID) { result in
                let newResult = result
                    .map { _ in } // Hides the result success type because we don't need it.
                    .mapError { _ in EditAddressError.unableToLoadCountries }
                promise(newResult)
            }
            self.stores.dispatch(action)
        }
        .eraseToAnyPublisher()
    }
}
