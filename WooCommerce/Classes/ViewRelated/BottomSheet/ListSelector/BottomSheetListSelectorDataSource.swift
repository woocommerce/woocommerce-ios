import UIKit

/// A generic data source for the bottom sheet list selector UI `BottomSheetListSelectorViewController`.
///
protocol BottomSheetListSelectorDataSource {
    associatedtype Model: Equatable
    associatedtype Cell: UITableViewCell

    /// A list of models to render the list.
    var data: [Model] { get }

    /// The model that is currently selected in the list.
    var selected: Model? { get }

    /// Called when a different model is selected.
    mutating func handleSelectedChange(selected: Model)

    /// Configures the selected UI.
    func isSelected(model: Model) -> Bool

    /// Configures the cell with the given model.
    func configureCell(cell: Cell, model: Model)
}
