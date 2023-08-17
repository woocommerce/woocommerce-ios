import Combine
import Yosemite
import Experiments
import class WordPressShared.EmailFormatValidator
import protocol Storage.StorageManagerType

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

    private let featureFlagService: FeatureFlagService

    /// Whether the Done button in the navigation bar is always enabled.
    ///
    private let isDoneButtonAlwaysEnabled: Bool

    /// Store for publishers subscriptions
    ///
    private var subscriptions = Set<AnyCancellable>()

    init(siteID: Int64,
         address: Address,
         phoneCountryCode: String = "",
         secondaryAddress: Address? = nil,
         isDoneButtonAlwaysEnabled: Bool = false,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         stores: StoresManager = ServiceLocator.stores,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         analytics: Analytics = ServiceLocator.analytics) {
        self.siteID = siteID

        self.originalAddress = address
        var fields: AddressFormFields = .init(with: originalAddress)
        fields.phoneCountryCode = phoneCountryCode
        self.fields = fields

        self.secondaryOriginalAddress = secondaryAddress ?? .empty
        self.secondaryFields = .init(with: secondaryOriginalAddress)

        self.isDoneButtonAlwaysEnabled = isDoneButtonAlwaysEnabled
        self.navigationTrailingItem = .done(enabled: isDoneButtonAlwaysEnabled)

        self.storageManager = storageManager
        self.stores = stores
        self.analytics = analytics

        self.featureFlagService = featureFlagService

        // Listen only to the first emitted event.
        onLoadTrigger.first().sink { [weak self] in
            guard let self = self else { return }
            self.bindSyncTrigger()
            self.bindNavigationTrailingItemPublisher()
            self.bindHasPendingChangesPublisher()

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
    @Published private(set) var navigationTrailingItem: AddressFormNavigationItem

    /// Define if the view should show placeholders instead of the real elements.
    ///
    @Published private(set) var showPlaceholders: Bool = false

    /// Defines the current notice that should be shown.
    /// Defaults to `nil`.
    ///
    @Published var notice: Notice?

    /// Whether the address form has any pending (unsaved) changes.
    ///
    /// Returns `true` if there are changes pending to commit. `False` otherwise.
    ///
    @Published private(set) var hasPendingChanges: Bool = false

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

    var showSearchButton: Bool {
        !featureFlagService.isFeatureFlagEnabled(.betterCustomerSelectionInOrder)
    }

    /// Creates a view model to be used when selecting a country for primary fields
    ///
    func createCountryViewModel() -> CountrySelectorViewModel {
        let selectedCountryBinding = Binding<AreaSelectorCommandProtocol?>(
            get: { self.fields.selectedCountry },
            set: { self.fields.selectedCountry = $0 as? Country}
        )
        return CountrySelectorViewModel(countries: allCountries, selected: selectedCountryBinding)
    }

    /// Creates a view model to be used when selecting a state for primary fields
    ///
    func createStateViewModel() -> StateSelectorViewModel {
        let selectedStateBinding = Binding<AreaSelectorCommandProtocol?>(
            get: { self.fields.selectedState },
            set: { self.fields.selectedState = $0 as? StateOfACountry}
        )

        // Sort states from the selected country
        let states = fields.selectedCountry?.states.sorted { $0.name < $1.name } ?? []
        return StateSelectorViewModel(states: states, selected: selectedStateBinding)
    }

    /// Creates a view model to be used when selecting a country for secondary fields
    ///
    func createSecondaryCountryViewModel() -> CountrySelectorViewModel {
        let selectedCountryBinding = Binding<AreaSelectorCommandProtocol?>(
            get: { self.secondaryFields.selectedCountry },
            set: { self.secondaryFields.selectedCountry = $0 as? Country}
        )
        return CountrySelectorViewModel(countries: allCountries, selected: selectedCountryBinding)
    }

    /// Creates a view model to be used when selecting a state for secondary fields
    ///
    func createSecondaryStateViewModel() -> StateSelectorViewModel {
        let selectedStateBinding = Binding<AreaSelectorCommandProtocol?>(
            get: { self.secondaryFields.selectedState },
            set: { self.secondaryFields.selectedState = $0 as? StateOfACountry}
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

    /// Fills Order AddressFormFields with Customer details
    ///
    func customerSelectedFromSearch(customer: Customer) {
        fillCustomerFields(customer: customer)
        let addressesDiffer = customer.billing != customer.shipping
        showDifferentAddressForm = addressesDiffer
    }

    private func fillCustomerFields(customer: Customer) {
        fields = populate(fields: fields, with: customer.billing)
        secondaryFields = populate(fields: secondaryFields, with: customer.shipping)
    }

    private func populate(fields: AddressFormFields, with address: Address?) -> AddressFormFields {
        var fields = fields

        fields.firstName = address?.firstName ?? ""
        fields.lastName = address?.lastName ?? ""
        // Email is declared optional because we're using the same property from the Address model
        // for both Shipping and Billing details:
        // https://github.com/woocommerce/woocommerce-ios/issues/7993
        fields.email = address?.email ?? ""
        fields.phone = address?.phone ?? ""
        fields.company = address?.company ?? ""
        fields.address1 = address?.address1 ?? ""
        fields.address2 = address?.address2 ?? ""
        fields.city = address?.city ?? ""
        fields.postcode = address?.postcode ?? ""
        fields.country = address?.country ?? ""
        fields.state = address?.state ?? ""

        return fields
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
            .map { [isDoneButtonAlwaysEnabled, originalAddress, secondaryOriginalAddress]
                fields, secondaryFields, showDifferentAddressForm, performingNetworkRequest -> AddressFormNavigationItem in
                guard !performingNetworkRequest else {
                    return .loading
                }

                guard !fields.useAsToggle else {
                    return .done(enabled: true)
                }

                guard !isDoneButtonAlwaysEnabled else {
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

    /// Determines whether the address form has pending changes, based on the navigation trailing item.
    ///
    func bindHasPendingChangesPublisher() {
        $navigationTrailingItem
            .map {
                $0 == .done(enabled: true)
            }
            .assign(to: &$hasPendingChanges)
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
