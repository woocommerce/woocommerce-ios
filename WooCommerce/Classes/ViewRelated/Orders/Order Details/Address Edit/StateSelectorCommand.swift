import Foundation
import Yosemite

/// Command to be used to select a state when editing addresses.
///
final class StateSelectorCommand: ObservableListSelectorCommand {
    typealias Model = StateOfACountry
    typealias Cell = BasicTableViewCell

    /// Original array of states.
    ///
    private let states: [StateOfACountry]

    /// Data to display
    ///
    @Published private(set) var data: [StateOfACountry]

    /// Current selected state
    ///
    @Binding private(set) var selected: StateOfACountry?

    /// Navigation bar title
    ///
    let navigationBarTitle: String? = ""

    init(states: [StateOfACountry], selected: Binding<StateOfACountry?>) {
        self.states = states
        self.data = states
        self._selected = selected
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
