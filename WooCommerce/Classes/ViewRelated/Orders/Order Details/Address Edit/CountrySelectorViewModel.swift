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
    let command: CountrySelectorCommand

    /// Navigation title
    ///
    let navigationTitle = Localization.title

    /// Filter text field placeholder
    ///
    let filterPlaceholder = Localization.placeholder

    /// Subscriptions store
    ///
    private var subscriptions = Set<AnyCancellable>()

    init(countries: [Country], selected: CurrentValueSubject<Country?, Never>) {
        self.command = CountrySelectorCommand(countries: countries, selected: selected.value)

        /// Bind selected country to the provided selected subject
        ///
        command.$selected.sink { country in
            selected.send(country)
        }.store(in: &subscriptions)
    }
}

// MARK: Constants
private extension CountrySelectorViewModel {
    enum Localization {
        static let title = NSLocalizedString("Country", comment: "Title to select country from the edit address screen")
        static let placeholder = NSLocalizedString("Filter Countries", comment: "Placeholder on the search field to search for a specific country")
    }
}
