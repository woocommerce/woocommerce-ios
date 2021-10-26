import Foundation
import Observables

/// Command to populate the order list date range filter list selector
///
final class OrderDateRangeFilterListSelectorCommand: ListSelectorCommand {
    typealias Cell = TitleAndValueTableViewCell
    typealias Model = FilterTypeViewModel

    var navigationBarTitle: String?

    let selected: FilterTypeViewModel? = nil

    fileprivate(set) var data: [FilterTypeViewModel]

    private let onItemSelectedSubject = PublishSubject<FilterTypeViewModel>()
    var onItemSelected: Observable<FilterTypeViewModel> {
        onItemSelectedSubject
    }

    init(data: [FilterTypeViewModel]) {
        self.data = data
    }

    func isSelected(model: FilterTypeViewModel) -> Bool {
        selected?.cellViewModel == model.cellViewModel
    }

    func handleSelectedChange(selected: FilterTypeViewModel, viewController: ViewController) {
        onItemSelectedSubject.send(selected)
    }

    func configureCell(cell: TitleAndValueTableViewCell, model: FilterTypeViewModel) {
        cell.selectionStyle = .default
        cell.updateUI(title: model.cellViewModel.title, value: model.cellViewModel.value)
        cell.accessoryType = .disclosureIndicator
    }
}
