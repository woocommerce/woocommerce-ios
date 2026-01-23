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
                                                          comment: "This text appears as the navigation bar title on a screen where users select a state/province when creating shipping labels for orders. It's displayed at the top of a list selector interface that allows users to choose from available states within a selected country.")
    }
}
