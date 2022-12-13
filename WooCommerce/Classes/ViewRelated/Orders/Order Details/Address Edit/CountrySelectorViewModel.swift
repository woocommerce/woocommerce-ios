import Combine
import SwiftUI
import Yosemite

/// View Model for the `CountrySelector` view.
///
final class CountrySelectorViewModel: FilterListSelectorViewModelable, ObservableObject {
    /// Current search term entered by the user.
    /// Each update will trigger an update to the `command` that contains the country data.
    var searchTerm: String = "" {
        didSet {
            command.filterAreas(term: searchTerm)
        }
    }

    /// Command that powers the `ListSelector` view.
    ///
    let command: AreaSelectorCommand

    /// Navigation title
    ///
    let navigationTitle = Localization.title

    /// Filter text field placeholder
    ///
    let filterPlaceholder = Localization.placeholder

    init(countries: [Country], selected: Binding<AreaSelectorCommandProtocol?>) {
        self.command = AreaSelectorCommand( areas: countries, selected: selected)
    }
}

// MARK: Constants
private extension CountrySelectorViewModel {
    enum Localization {
        static let title = NSLocalizedString("Country", comment: "Title to select country from the edit address screen")
        static let placeholder = NSLocalizedString("Filter Countries", comment: "Placeholder on the search field to search for a specific country")
    }
}
