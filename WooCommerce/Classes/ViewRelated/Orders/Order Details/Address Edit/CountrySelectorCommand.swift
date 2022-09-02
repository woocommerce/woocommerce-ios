import Foundation
import Yosemite
import SwiftUI

protocol CommonProtocol {
    //var navigationBarTitle: String? { get }
    var name: String { get }
    var code: String { get }
}

extension Country: CommonProtocol {}
/// Command to be used to select a country when editing addresses.
///
final class CountrySelectorCommand: ObservableListSelectorCommand {
    //typealias Model = CommonProtocol
    //typealias Cell = BasicTableViewCell

    /// Original array of countries.
    ///
    private let countries: [CommonProtocol]

    /// Data to display
    ///
    @Published private(set) var data: [CommonProtocol]

    /// Current selected country
    ///
    @Binding private(set) var selected: CommonProtocol?

    /// Navigation bar title
    ///
    var navigationBarTitle: String? = ""

    init(countries: [CommonProtocol], selected: Binding<CommonProtocol?>) {
        self.countries = countries
        self.data = countries
        self._selected = selected
    }

    func handleSelectedChange(selected: CommonProtocol, viewController: ViewController) {
        self.selected = selected
        viewController.navigationController?.popViewController(animated: true)
    }

    func isSelected(model: CommonProtocol) -> Bool {
        model.code == selected?.code // I'm only comparing country codes because states can be unsorted
        //model == selected
    }

    func configureCell(cell: BasicTableViewCell, model: CommonProtocol) {
        cell.textLabel?.text = model.name
    }

    /// Filter available countries that contains a given search term.
    ///
    func filterCountries(term: String) {
        guard term.isNotEmpty else {
            return data = countries
        }

        // Trim the search term to remove newlines or whitespaces (e.g added from the keyboard predictive text) from both ends
        data = countries.filter { $0.name.localizedCaseInsensitiveContains(term.trim()) }
    }
}
