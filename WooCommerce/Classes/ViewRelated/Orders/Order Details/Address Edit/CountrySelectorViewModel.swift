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
            objectWillChange.send()
        }
    }

    /// ResultsController for stored countries, replaces `command` with new content.
    ///
    private lazy var countriesResultsController: ResultsController<StorageCountry> = {
        let countriesDescriptor = NSSortDescriptor(key: "name", ascending: true)
        let resultsController = ResultsController<StorageCountry>(storageManager: storageManager, sortedBy: [countriesDescriptor])

        resultsController.onDidChangeContent = { [weak self] in
            self?.command = CountrySelectorCommand(countries: resultsController.fetchedObjects)
        }
        return resultsController
    }()

    /// Command that powers the `ListSelector` view.
    ///
    private(set) var command = CountrySelectorCommand(countries: []) {
        didSet {
            objectWillChange.send()
        }
    }

    /// Navigation title
    ///
    let navigationTitle = Localization.title

    /// Filter text field placeholder
    ///
    let filterPlaceholder = Localization.placeholder

    /// Storage to fetch Countries
    ///
    private let storageManager: StorageManagerType

    init(storageManager: StorageManagerType = ServiceLocator.storageManager) {
        self.storageManager = storageManager

        // Perform initial fetch
        try? countriesResultsController.performFetch()
    }
}

// MARK: Constants
private extension CountrySelectorViewModel {
    enum Localization {
        static let title = NSLocalizedString("Country", comment: "Title to select country from the edit address screen")
        static let placeholder = NSLocalizedString("Filter Countries", comment: "Placeholder on the search field to search for a specific country")
    }
}
