import Foundation
import Yosemite
import SwiftUI

protocol CommonProtocol {
    var name: String { get }
    var code: String { get }
}

extension Country: CommonProtocol {}

public final class CommonSelectorCommand: ObservableListSelectorCommand {
    /// Original array of countries or states.
    ///
    private let countriesOrStates: [CommonProtocol]

    /// Data to display
    ///
    @Published private(set) var data: [CommonProtocol]

    /// Current selected country
    ///
    @Binding private(set) var selected: CommonProtocol?

    /// Navigation bar title
    ///
    var navigationBarTitle: String? = ""

    init(countriesOrStates: [CommonProtocol], selected: Binding<CommonProtocol?>) {
        self.countriesOrStates = countriesOrStates
        self.data = countriesOrStates
        self._selected = selected
    }

    func handleSelectedChange(selected: CommonProtocol, viewController: ViewController) {
        self.selected = selected
        viewController.navigationController?.popViewController(animated: true)
    }

    func isSelected(model: CommonProtocol) -> Bool {
        model.code == selected?.code
    }

    func configureCell(cell: BasicTableViewCell, model: CommonProtocol) {
        cell.textLabel?.text = model.name
    }

    /// Filter available countries or states that contains a given search term.
    ///
    func filterCountriesOrStates(term: String) {
        guard term.isNotEmpty else {
            return data = countriesOrStates
        }

        // Trim the search term to remove newlines or whitespaces (e.g added from the keyboard predictive text) from both ends
        data = countriesOrStates.filter { $0.name.localizedCaseInsensitiveContains(term.trim()) }
    }
}
