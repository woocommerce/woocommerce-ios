import Foundation
import Yosemite

/// Command to be used to select a country when editing addresses.
///
final class CountrySelectorCommand: ObservableListSelectorCommand {
    typealias Model = Country
    typealias Cell = BasicTableViewCell

    /// Original array of countries.
    ///
    private let countries: [Country]

    /// Data to display
    ///
    @Published private(set) var data: [Country]

    /// Current selected country
    ///
    @Binding private(set) var selected: Country?

    /// Navigation bar title
    ///
    let navigationBarTitle: String? = ""

    init(countries: [Country], selected: Binding<Country?>) {
        self.countries = countries
        self.data = countries
        self._selected = selected
    }

    func handleSelectedChange(selected: Country, viewController: ViewController) {
        self.selected = selected
    }

    func isSelected(model: Country) -> Bool {
        model.code == selected?.code // I'm only comparing country codes because states can be unsorted
    }

    func configureCell(cell: BasicTableViewCell, model: Country) {
        cell.textLabel?.text = model.name
    }

    /// Filter available countries that contains a given search term.
    ///
    func filterCountries(term: String) {
        guard term.isNotEmpty else {
            return data = countries
        }

        data = countries.filter { $0.name.localizedCaseInsensitiveContains(term) }
    }
}
