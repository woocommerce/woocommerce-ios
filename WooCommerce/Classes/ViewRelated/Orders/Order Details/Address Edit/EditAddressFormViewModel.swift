import Yosemite
import Storage
import Combine

final class EditAddressFormViewModel: ObservableObject {

    /// Current site ID
    ///
    private let siteID: Int64

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

    init(siteID: Int64, address: Address?, storageManager: StorageManagerType = ServiceLocator.storageManager, stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.originalAddress = address ?? .empty
        self.storageManager = storageManager
        self.stores = stores
        updateFieldsWithOriginalAddress()
        bindSyncTrigger()
        fetchStoredCountriesAndTriggerSyncIfNeeded()
    }

    /// Original `Address` model.
    ///
    private let originalAddress: Address

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

    /// Define if the view should show placeholders instead of the real elements.
    ///
    @Published private(set) var showPlaceholders: Bool = false

    /// Return `true` if the done button should be enabled.
    ///
    var isDoneButtonEnabled: Bool {
        return originalAddress != addressFromFields
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

    var addressFromFields: Address {
        Address(firstName: firstName,
                lastName: lastName,
                company: company.isEmpty ? nil : company,
                address1: address1,
                address2: company.isEmpty ? nil : company,
                city: city,
                state: originalAddress.state, // TODO: replace with local value
                postcode: postcode,
                country: originalAddress.country, // TODO: replace with local value
                phone: phone.isEmpty ? nil : phone,
                email: email.isEmpty ? nil : email)
    }


    /// Fetches countries from storage, If there are no stored countries, trigger a sync request.
    ///
    func fetchStoredCountriesAndTriggerSyncIfNeeded() {
        // Initial fetch
        try? countriesResultsController.performFetch()

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

            let action = DataAction.synchronizeCountries(siteID: self.siteID) { result in
                let newResult = result.map { _ in } // Hides the result success type because we don't need it.
                promise(newResult)
            }
            self.stores.dispatch(action)
        }
        .eraseToAnyPublisher()
    }
}
