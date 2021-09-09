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
    let command = CountrySelectorCommand(countries: [])

    /// Navigation title
    ///
    let navigationTitle = Localization.title

    /// Filter text field placeholder
    ///
    let filterPlaceholder = Localization.placeholder

    /// Current `SiteID`, needed to sync countries from a remote source.
    ///
    private let siteID: Int64

    init(siteID: Int64) {
        self.siteID = siteID
    }
}

// MARK: Constants
private extension CountrySelectorViewModel {
    enum Localization {
        static let title = NSLocalizedString("Country", comment: "Title to select country from the edit address screen")
        static let placeholder = NSLocalizedString("Filter Countries", comment: "Placeholder on the search field to search for a specific country")
    }
}
