import Yosemite
import Storage
import Combine

final class EditAddressFormViewModel: ObservableObject {

    enum AddressType {
        case shipping
        case billing
    }

    /// Type of order address to edit
    ///
    let type: AddressType

    /// Order update callback
    ///
    private let onOrderUpdate: ((Yosemite.Order) -> Void)?

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
    private let stores: StoresManager

    /// Store for publishers subscriptions
    ///
    private var subscriptions = Set<AnyCancellable>()

    init(order: Yosemite.Order,
         type: AddressType,
         onOrderUpdate: ((Yosemite.Order) -> Void)? = nil,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         stores: StoresManager = ServiceLocator.stores) {
        self.order = order
        self.type = type
        self.onOrderUpdate = onOrderUpdate

        let addressToEdit: Address?
        switch type {
        case .shipping:
            addressToEdit = order.shippingAddress
        case .billing:
            addressToEdit = order.billingAddress
        }
        self.originalAddress = addressToEdit ?? .empty

        self.storageManager = storageManager
        self.stores = stores

        // Listen only to the first emitted event.
        onLoadTrigger.first().sink { [weak self] in
            guard let self = self else { return }
            self.bindSyncTrigger()
            self.bindSelectedCountryAndStateIntoFields()
            self.bindNavigationTrailingItemPublisher()

            self.fetchStoredCountriesAndTriggerSyncIfNeeded()
            self.setFieldsInitialValues()
        }.store(in: &subscriptions)
    }

    /// Original `Address` model.
    ///
    private let originalAddress: Address

    /// Current selected country.
    ///
    @Published private var selectedCountry: Yosemite.Country?

    /// Current selected state.
    ///
    @Published private var selectedState: Yosemite.StateOfACountry?

    /// Address form fields
    ///
    @Published var fields = FormFields()

    /// Order to be edited.
    ///
    private let order: Yosemite.Order

    /// Trigger to perform any one time setups.
    ///
    let onLoadTrigger: PassthroughSubject<Void, Never> = PassthroughSubject()

    /// Tracks if a network request is being performed.
    ///
    private let performingNetworkRequest: CurrentValueSubject<Bool, Never> = .init(false)

    /// Active navigation bar trailing item.
    /// Defaults to a disabled done button.
    ///
    @Published private(set) var navigationTrailingItem: NavigationItem = .done(enabled: false)

    /// Define if the view should show placeholders instead of the real elements.
    ///
    @Published private(set) var showPlaceholders: Bool = false

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

    /// Update the address remotely and invoke a completion block when finished
    ///
    func updateRemoteAddress(onFinish: @escaping (Bool) -> Void) {
        let updatedAddress = fields.toAddress(country: selectedCountry, state: selectedState)

        let modifiedOrder: Yosemite.Order
        switch type {
        case .shipping:
            modifiedOrder = order.copy(shippingAddress: updatedAddress)
        case .billing:
            modifiedOrder = order.copy(billingAddress: updatedAddress)
        }

        let action = OrderAction.updateOrder(siteID: order.siteID,
                                             order: modifiedOrder,
                                             fields: [type == .shipping ? .shippingAddress : .billingAddress]) { [weak self] result in
            guard let self = self else { return }

            self.performingNetworkRequest.send(false)
            // TODO: add success/failure notice
            switch result {
            case .success(let updatedOrder):
                self.onOrderUpdate?(updatedOrder)
            case .failure:
                break
            }
            onFinish(result.isSuccess)
        }

        performingNetworkRequest.send(true)
        stores.dispatch(action)
    }
}

extension EditAddressFormViewModel {
    /// Representation of possible navigation bar trailing buttons
    ///
    enum NavigationItem: Equatable {
        case done(enabled: Bool)
        case loading
    }

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
        }

        mutating func update(with country: Yosemite.Country?, and state: Yosemite.StateOfACountry?) {
            self.country = country?.name ?? self.country
            self.state = state?.name ?? self.state
        }

        func toAddress(country: Yosemite.Country?, state: Yosemite.StateOfACountry?) -> Yosemite.Address {
            Address(firstName: firstName,
                    lastName: lastName,
                    company: company.isEmpty ? nil : company,
                    address1: address1,
                    address2: address2.isEmpty ? nil : address2,
                    city: city,
                    state: state?.code ?? self.state,
                    postcode: postcode,
                    country: country?.code ?? self.country,
                    phone: phone.isEmpty ? nil : phone,
                    email: email.isEmpty ? nil : email)
        }
    }
}

private extension EditAddressFormViewModel {
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
            .map { [originalAddress] fields, performingNetworkRequest, selectedCountry, selectedState -> NavigationItem in
                guard !performingNetworkRequest else {
                    return .loading
                }
                return .done(enabled: originalAddress != fields.toAddress(country: selectedCountry, state: selectedState))
            }
            .assign(to: &$navigationTrailingItem)
    }

    /// Update published fields when the selected country and state is updated.
    /// If the current selected state does not exists within the selected country, then the state is nilled.
    ///
    func bindSelectedCountryAndStateIntoFields() {

        typealias StatePublisher = AnyPublisher<Yosemite.StateOfACountry?, Never>

        // When a country is selected, check if the current state is a valid state for that country, otherwise `nil` it.
        $selectedCountry
            .withLatestFrom($selectedState)
            .flatMap { country, state -> StatePublisher in
                guard let country = country, let state = state, country.states.contains(state) else {
                    return StatePublisher.init(Empty())
                }
                return StatePublisher.init(Just(state))
            }
            .assign(to: &$selectedState)


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
        syncCountriesTrigger
            .handleEvents(receiveOutput: { // Set `showPlaceholders` to `true` before initiating sync.
                self.showPlaceholders = true // I could not find a way to assign this using combine operators. :-(
            })
            .map { // Sync countries
                self.makeSyncCountriesFuture()
                    .replaceError(with: ()) // TODO: Handle errors
            }
            .switchToLatest()
            .map { _ in // Set `showPlaceholders` to `false` after sync is done.
                false
            }
            .assign(to: &$showPlaceholders)
    }

    /// Creates a publisher that syncs countries into our storage layer.
    ///
    func makeSyncCountriesFuture() -> AnyPublisher<Void, Error> {
        Future<Void, Error> { [weak self] promise in
            guard let self = self else { return }

            let action = DataAction.synchronizeCountries(siteID: self.order.siteID) { result in
                let newResult = result.map { _ in } // Hides the result success type because we don't need it.
                promise(newResult)
            }
            self.stores.dispatch(action)
        }
        .eraseToAnyPublisher()
    }
}
