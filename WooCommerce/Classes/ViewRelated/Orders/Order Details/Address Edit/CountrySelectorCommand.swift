import Foundation
import Yosemite

/// Command to be used to select a country when editing addresses.
///
final class CountrySelectorCommand: ListSelectorCommand {
    /// Data to display
    ///
    let data: [Country]

    /// Current selected country
    ///
    private(set) var selected: Country?

    /// Navigation bar title
    ///
    let navigationBarTitle: String? = ""

    init(countries: [Country], selected: Country?) {
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
}
