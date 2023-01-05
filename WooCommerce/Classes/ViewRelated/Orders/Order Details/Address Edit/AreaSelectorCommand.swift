import Foundation
import Yosemite
import SwiftUI

protocol AreaSelectorCommandProtocol {
    var name: String { get }
    var code: String { get }
}

extension Country: AreaSelectorCommandProtocol {}
extension StateOfACountry: AreaSelectorCommandProtocol {}

final class AreaSelectorCommand: ObservableListSelectorCommand {
    /// Original array of areas
    ///
    private let areas: [AreaSelectorCommandProtocol]

    /// Data to display
    ///
    @Published private(set) var data: [AreaSelectorCommandProtocol]

    /// Current selected area
    ///
    @Binding private(set) var selected: AreaSelectorCommandProtocol?

    /// Navigation bar title
    ///
    var navigationBarTitle: String? = ""

    init(areas: [AreaSelectorCommandProtocol], selected: Binding<AreaSelectorCommandProtocol?>) {
        self.areas = areas
        self.data = areas
        self._selected = selected
    }

    func handleSelectedChange(selected: AreaSelectorCommandProtocol, viewController: ViewController) {
        self.selected = selected
        viewController.navigationController?.popViewController(animated: true)
    }

    func isSelected(model: AreaSelectorCommandProtocol) -> Bool {
        (model.code == selected?.code) && (model.name == selected?.name)
    }

    func configureCell(cell: BasicTableViewCell, model: AreaSelectorCommandProtocol) {
        cell.textLabel?.text = model.name
    }

    /// Filter available areas that contains a given search term.
    ///
    func filterAreas(term: String) {
        guard term.isNotEmpty else {
            return data = areas
        }

        // Trim the search term to remove newlines or whitespaces (e.g added from the keyboard predictive text) from both ends
        data = areas.filter { $0.name.localizedCaseInsensitiveContains(term.trim()) }
    }
}
