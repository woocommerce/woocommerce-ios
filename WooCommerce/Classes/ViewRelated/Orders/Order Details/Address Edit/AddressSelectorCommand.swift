import Foundation
import Yosemite
import SwiftUI

protocol AddressSelectorCommandProtocol {
    var name: String { get }
    var code: String { get }
}

extension Country: AddressSelectorCommandProtocol {}
extension StateOfACountry: AddressSelectorCommandProtocol {}

final class AddressSelectorCommand: ObservableListSelectorCommand {
    /// Original array of countries or states.
    ///
    private let countriesOrStates: [AddressSelectorCommandProtocol]

    /// Data to display
    ///
    @Published private(set) var data: [AddressSelectorCommandProtocol]

    /// Current selected country or state
    ///
    @Binding private(set) var selected: AddressSelectorCommandProtocol?

    /// Navigation bar title
    ///
    var navigationBarTitle: String? = ""

    init(countriesOrStates: [AddressSelectorCommandProtocol], selected: Binding<AddressSelectorCommandProtocol?>) {
        self.countriesOrStates = countriesOrStates
        self.data = countriesOrStates
        self._selected = selected
    }

    func handleSelectedChange(selected: AddressSelectorCommandProtocol, viewController: ViewController) {
        self.selected = selected
        viewController.navigationController?.popViewController(animated: true)
    }

    func isSelected(model: AddressSelectorCommandProtocol) -> Bool {
        (model.code == selected?.code) && (model.name == selected?.name)
    }

    func configureCell(cell: BasicTableViewCell, model: AddressSelectorCommandProtocol) {
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
