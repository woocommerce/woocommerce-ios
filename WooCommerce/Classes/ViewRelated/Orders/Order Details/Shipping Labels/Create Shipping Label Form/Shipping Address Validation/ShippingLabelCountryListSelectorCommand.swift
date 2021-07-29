import Foundation
import Yosemite

final class ShippingLabelCountryListSelectorCommand: ListSelectorCommand {
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
    let navigationBarTitle: String? = Localization.navigationBarTitle

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

private extension ShippingLabelCountryListSelectorCommand {
    enum Localization {
        static var navigationBarTitle = NSLocalizedString("Choose a Country", comment: "Navigation title on the shipping label country selector screen")
    }
}
