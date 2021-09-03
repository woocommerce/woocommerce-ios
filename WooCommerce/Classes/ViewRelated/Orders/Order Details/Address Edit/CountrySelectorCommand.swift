import Foundation
import Yosemite

/// Command to be used to select a country when editing addresses.
///
final class CountrySelectorCommand: ListSelectorCommand {
    typealias Model = Country
    typealias Cell = BasicTableViewCell

    /// Data to display
    ///
    let data: [Country]

    /// Current selected country
    ///
    private(set) var selected: Country?

    /// Navigation bar title
    ///
    let navigationBarTitle: String? = ""

    init(countries: [Country] = temporaryCountries(), selected: Country? = nil) {
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

    // TESTING HELPER, WILL BE REMOVED LATER.
    private static func temporaryCountries() -> [Country] {
        return Locale.isoRegionCodes.map { regionCode in
            let name = Locale.current.localizedString(forRegionCode: regionCode) ?? ""
            return Country(code: regionCode, name: name, states: [])
        }
    }
}
