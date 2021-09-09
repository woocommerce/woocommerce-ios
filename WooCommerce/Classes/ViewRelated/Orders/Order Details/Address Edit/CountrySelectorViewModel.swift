import Combine
import SwiftUI
import Yosemite
import protocol Storage.StorageManagerType

/// View Model for the `CountrySelector` view.
///
final class CountrySelectorViewModel: FilterListSelectorViewModelable, ObservableObject {

    /// Current search term entered by the user.
    /// Each update will trigger an update to the `command` that contains the country data.
    var searchTerm: String = "" {
        didSet {
            command.filterCountries(term: searchTerm)
        }
    }

    /// Define if the view should show placeholders instead of the real elements.
    ///
    @Published private(set) var showPlaceholders: Bool = false

    /// Command that powers the `ListSelector` view.
    ///
    let command = CountrySelectorCommand(countries: [])

    /// Navigation title
    ///
    let navigationTitle = Localization.title

    /// Filter text field placeholder
    ///
    let filterPlaceholder = Localization.placeholder

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

    /// Current `SiteID`, needed to sync countries from a remote source.
    ///
    private let siteID: Int64

    init(siteID: Int64, storageManager: StorageManagerType = ServiceLocator.storageManager, stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.storageManager = storageManager
        self.stores = stores
        bindSyncTrigger()
        bindStoredCountries()
    }
}

// MARK: Helpers
private extension CountrySelectorViewModel {
    /// Fetches & Binds countries from storage, If there are no stored countries, trigger a sync request.
    ///
    func bindStoredCountries() {

        // Bind stored countries & command
        countriesResultsController.onDidChangeContent = { [weak self] in
            guard let self = self else { return }
            self.command.resetCountries(self.countriesResultsController.fetchedObjects)
        }

        // Initial fetch
        try? countriesResultsController.performFetch()

        // Trigger a sync request if there are no countries.
        guard !countriesResultsController.isEmpty else {
            return syncCountriesTrigger.send()
        }

        // Reset countries with fetched
        command.resetCountries(countriesResultsController.fetchedObjects)
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

// MARK: Constants
private extension CountrySelectorViewModel {
    enum Localization {
        static let title = NSLocalizedString("Country", comment: "Title to select country from the edit address screen")
        static let placeholder = NSLocalizedString("Filter Countries", comment: "Placeholder on the search field to search for a specific country")
    }
}
