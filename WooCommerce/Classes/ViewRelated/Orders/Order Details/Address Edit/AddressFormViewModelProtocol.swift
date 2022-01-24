import Combine
import Yosemite
import protocol Storage.StorageManagerType

/// Protocol to describe viewmodel of editable address
///
protocol AddressFormViewModelProtocol: ObservableObject {

    /// Address form fields
    ///
    var fields: AddressFormFields { get set }

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

    /// Defines if the email field should be shown
    ///
    var showEmailField: Bool { get }

    /// Defines navbar title
    ///
    var viewTitle: String { get }

    /// Defines address section title
    ///
    var sectionTitle: String { get }

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

    /// Save the address and invoke a completion block when finished
    ///
    func saveAddress(onFinish: @escaping (Bool) -> Void)

    /// Track the flow cancel scenario.
    ///
    func userDidCancelFlow()

    /// Creates a view model to be used when selecting a country
    ///
    func createCountryViewModel() -> CountrySelectorViewModel

    /// Creates a view model to be used when selecting a state
    ///
    func createStateViewModel() -> StateSelectorViewModel
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

    mutating func update(with address: Address) {
        firstName = address.firstName
        lastName = address.lastName
        email = address.email ?? ""
        phone = address.phone ?? ""

        company = address.company ?? ""
        address1 = address.address1
        address2 = address.address2 ?? ""
        city = address.city
        postcode = address.postcode

        // Only use the address.state if we haven't set a value before.
        // Like when selecting a state from the picker
        state = state.isEmpty ? address.state : state
    }

    mutating func update(with country: Country?, and state: StateOfACountry?) {
        self.country = country?.name ?? self.country
        self.state = state?.name ?? self.state
    }

    func toAddress(country: Country?, state: StateOfACountry?) -> Yosemite.Address {
        Address(firstName: firstName,
                lastName: lastName,
                company: company,
                address1: address1,
                address2: address2,
                city: city,
                state: state?.code ?? self.state,
                postcode: postcode,
                country: country?.code ?? self.country,
                phone: phone,
                email: email)
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
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        self.siteID = siteID
        self.originalAddress = address

        self.storageManager = storageManager
        self.stores = stores
        self.analytics = analytics

        // Listen only to the first emitted event.
        onLoadTrigger.first().sink { [weak self] in
            guard let self = self else { return }
            self.bindSyncTrigger()
            self.bindSelectedCountryAndStateIntoFields()
            self.bindNavigationTrailingItemPublisher()

            self.fetchStoredCountriesAndTriggerSyncIfNeeded()
            self.setFieldsInitialValues()

            self.trackOnLoad()
        }.store(in: &subscriptions)
    }

    private let siteID: Int64

    /// Original `Address` model.
    ///
    private let originalAddress: Address

    /// Updated `Address`, constructed from `fields`,  `selectedCountry`, `selectedState`.
    ///
    var updatedAddress: Address {
        fields.toAddress(country: selectedCountry, state: selectedState)
    }

    /// Current selected country.
    ///
    @Published private var selectedCountry: Yosemite.Country?

    /// Current selected state.
    ///
    @Published private var selectedState: Yosemite.StateOfACountry?

    /// Address form fields
    ///
    @Published var fields = AddressFormFields()

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
    @Published var presentNotice: Notice?

    /// Defines if the state field should be defined as a list selector.
    ///
    var showStateFieldAsSelector: Bool {
        selectedCountry?.states.isNotEmpty ?? false
    }

    /// Creates a view model to be used when selecting a country
    ///
    func createCountryViewModel() -> CountrySelectorViewModel {
        let selectedCountryBinding = Binding(
            get: { self.selectedCountry },
            set: { self.selectedCountry = $0 }
        )
        return CountrySelectorViewModel(countries: countriesResultsController.fetchedObjects, selected: selectedCountryBinding)
    }

    /// Creates a view model to be used when selecting a state
    ///
    func createStateViewModel() -> StateSelectorViewModel {
        let selectedStateBinding = Binding(
            get: { self.selectedState },
            set: { self.selectedState = $0 }
        )

        // Sort states from the selected country
        let states = selectedCountry?.states.sorted { $0.name < $1.name } ?? []
        return StateSelectorViewModel(states: states, selected: selectedStateBinding)
    }

    /// Track the flow start. Override in subclass.
    ///
    func trackOnLoad() {
        // override in subclass
    }
}

extension AddressFormViewModel {

    /// Representation of possible notices that can be displayed
    enum Notice: Equatable {
        case success
        case error(EditAddressError)
    }

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
}

private extension AddressFormViewModel {
    /// Set initial values from `originalAddress` using the stored countries to compute the current selected country & state.
    ///
    func setFieldsInitialValues() {
        selectedCountry = countriesResultsController.fetchedObjects.first { $0.code == originalAddress.country }
        selectedState = selectedCountry?.states.first { $0.code == originalAddress.state }
        fields.update(with: originalAddress)
    }

    /// Calculates what navigation trailing item should be shown depending on our internal state.
    ///
    func bindNavigationTrailingItemPublisher() {
        Publishers.CombineLatest4($fields, performingNetworkRequest, $selectedCountry, $selectedState)
            .map { [originalAddress] fields, performingNetworkRequest, selectedCountry, selectedState -> AddressFormNavigationItem in
                guard !performingNetworkRequest else {
                    return .loading
                }

                guard !fields.useAsToggle else {
                    return .done(enabled: true)
                }

                return .done(enabled: originalAddress != fields.toAddress(country: selectedCountry, state: selectedState))
            }
            .assign(to: &$navigationTrailingItem)
    }

    /// Update published fields when the selected country and state is updated.
    /// If the selected country changes and it has a specific state to choose, clear the previous selected state.
    ///
    func bindSelectedCountryAndStateIntoFields() {

        typealias StatePublisher = AnyPublisher<Yosemite.StateOfACountry?, Never>

        // When a country is selected, check if the new country has a state list.
        // If it has, clear the selected state and the state field.
        // If it doesn't only clear the selected state
        $selectedCountry
            .withLatestFrom($selectedState)
            .map { country, state -> String in
                guard let country = country else {
                    return ""
                }
                let currentStateName = state?.name ?? ""
                return country.states.isEmpty ? currentStateName : ""
            }
            .sink { stateName in
                self.selectedState = nil
                self.fields.state = stateName
            }
            .store(in: &subscriptions)

        // Update fields with new selections.
        Publishers.CombineLatest($selectedCountry, $selectedState)
            .sink { [weak self] country, state in
                self?.fields.update(with: country, and: state)
            }
            .store(in: &subscriptions)
    }

    /// Fetches countries from storage, If there are no stored countries, trigger a sync request.
    ///
    func fetchStoredCountriesAndTriggerSyncIfNeeded() {
        // Initial fetch
        try? countriesResultsController.performFetch()

        // Updates the initial fields when/if the data store changes(after sync).
        countriesResultsController.onDidChangeContent = { [weak self] in
            self?.setFieldsInitialValues()
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
                self?.presentNotice = .error(error)
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
