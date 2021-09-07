import Foundation
import Yosemite

/// Command to be used to select a state when editing addresses.
///
final class StateSelectorCommand: ListSelectorCommand {
    typealias Model = StateOfACountry
    typealias Cell = BasicTableViewCell

    /// Original array of countries.
    ///
    private let states: [StateOfACountry]

    /// Data to display
    ///
    private(set) var data: [StateOfACountry]

    /// Current selected country
    ///
    private(set) var selected: StateOfACountry?

    /// Navigation bar title
    ///
    let navigationBarTitle: String? = ""

    init(states: [StateOfACountry] = temporaryStates, selected: StateOfACountry? = nil) {
        self.states = states
        self.data = states
        self.selected = selected
    }

    func handleSelectedChange(selected: StateOfACountry, viewController: ViewController) {
        self.selected = selected
    }

    func isSelected(model: StateOfACountry) -> Bool {
        model == selected
    }

    func configureCell(cell: BasicTableViewCell, model: StateOfACountry) {
        cell.textLabel?.text = model.name
    }

    /// Filter available states that contains a given search term.
    ///
    func filterStates(term: String) {
        guard term.isNotEmpty else {
            return data = states
        }

        data = states.filter { $0.name.localizedCaseInsensitiveContains(term) }
    }
}

// MARK: Temporary Methods
extension StateSelectorCommand {

    // Supported states will come from the view model later.
    //
    private static let temporaryStates: [StateOfACountry] = {
        return Locale.isoRegionCodes.map { regionCode in
            let name = Locale.current.localizedString(forRegionCode: regionCode) ?? ""
            return StateOfACountry(code: regionCode, name: name)
        }
    }()
}
