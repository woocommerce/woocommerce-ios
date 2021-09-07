import Combine

/// View Model for the `CountrySelector` view.
///
final class CountrySelectorViewModel: ObservableObject {

    /// Current search term entered by the user.
    /// Each update will trigger an update to the `command` that contains the country data.
    @Published var searchTerm = "" {
        didSet {
            command.filterCountries(term: searchTerm)
        }
    }

    /// Command that powers the `ListSelector` view.
    ///
    let command = CountrySelectorCommand()
}
