import Foundation
import Yosemite

/// Command to populate the shipping label states of a country list selector
///
final class ShippingLabelStateOfACountryListSelectorCommand: ListSelectorCommand {
    typealias Model = StateOfACountry
    typealias Cell = BasicTableViewCell

    /// Data to display
    ///
    let data: [StateOfACountry]

    /// Holds the current selected state
    ///
    private(set) var selected: StateOfACountry?

    /// Navigation bar title
    ///
    let navigationBarTitle: String? = Localization.navigationBarTitle

    func handleSelectedChange(selected: StateOfACountry, viewController: ViewController) {
        self.selected = selected
    }

    func isSelected(model: StateOfACountry) -> Bool {
        selected == model
    }

    func configureCell(cell: BasicTableViewCell, model: StateOfACountry) {
        cell.textLabel?.text = model.name
    }

    init(states: [StateOfACountry], selected: StateOfACountry?) {
        self.data = states
        self.selected = selected
    }
}

// MARK: Constants
private extension ShippingLabelStateOfACountryListSelectorCommand {
    enum Localization {
        static let navigationBarTitle = NSLocalizedString("Choose a State",
                                                          comment: "Navigation title on the shipping label states of a country selector screen")
    }
}
