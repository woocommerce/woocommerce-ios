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

    /// Command that powers the `ListSelector` view.
    ///
    private(set) var command = CountrySelectorCommand(countries: [])

    /// ResultsController for stored countries.
    ///
    private lazy var countriesResultsController: ResultsController<StorageCountry> = {
        let countriesDescriptor = NSSortDescriptor(key: "name", ascending: true)
        return ResultsController<StorageCountry>(storageManager: storageManager, sortedBy: [countriesDescriptor])
    }()

    /// Navigation title
    ///
    let navigationTitle = Localization.title

    /// Filter text field placeholder
    ///
    let filterPlaceholder = Localization.placeholder

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
        fetchAndBindCountries()
    }
}

// MARK: Helpers
private extension CountrySelectorViewModel {
    /// Fetches & Binds countries from storage, If there are no stored countries, sync them from a remote source.
    ///
    func fetchAndBindCountries() {
        // Bind stored countries & command
        countriesResultsController.onDidChangeContent = { [weak self] in
            guard let self = self else { return }
            self.command.resetCountries(self.countriesResultsController.fetchedObjects)
        }

        // Initial fetch
        try? countriesResultsController.performFetch()

        // Reset countries with fetched data or sync countries if needed.
        if !countriesResultsController.isEmpty {
            command.resetCountries(countriesResultsController.fetchedObjects)
        } else {
            let action = DataAction.synchronizeCountries(siteID: siteID, onCompletion: { _ in })
            stores.dispatch(action)
        }
    }
}

// MARK: Constants
private extension CountrySelectorViewModel {
    enum Localization {
        static let title = NSLocalizedString("Country", comment: "Title to select country from the edit address screen")
        static let placeholder = NSLocalizedString("Filter Countries", comment: "Placeholder on the search field to search for a specific country")
    }
}
