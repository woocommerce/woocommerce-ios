import Foundation
import Yosemite

/// Command to be used to select a country when editing addresses.
///
final class CountrySelectorCommand: ListSelectorCommand {
    typealias Model = Country
    typealias Cell = BasicTableViewCell

    /// Original array of countries.
    ///
    private let countries: [Country]

    /// Data to display
    ///
    private(set) var data: [Country]

    /// Current selected country
    ///
    private(set) var selected: Country?

    /// Navigation bar title
    ///
    let navigationBarTitle: String? = ""

    init(countries: [Country] = temporaryCountries, selected: Country? = nil) {
        self.countries = countries
        self.data = countries
        self.selected = selected
    }

    func handleSelectedChange(selected: Country, viewController: ViewController) {
        self.selected = selected
    }

    func isSelected(model: Country) -> Bool {
        model == selected
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

        data = countries.filter { $0.name.contains(term) }
    }
}

// MARK: Temporary Methods
extension CountrySelectorCommand {

    // Supported countries will come from the view model later.
    //
    private static let temporaryCountries: [Country] = {
        return Locale.isoRegionCodes.map { regionCode in
            let name = Locale.current.localizedString(forRegionCode: regionCode) ?? ""
            return Country(code: regionCode, name: name, states: [])
        }
    }()
}
