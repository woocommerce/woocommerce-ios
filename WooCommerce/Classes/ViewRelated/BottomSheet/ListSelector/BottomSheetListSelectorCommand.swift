import UIKit

/// A generic interface for rendering the bottom sheet list selector UI `BottomSheetListSelectorViewController`.
///
protocol BottomSheetListSelectorCommand {
    associatedtype Model: Equatable
    associatedtype Cell: UITableViewCell

    /// A list of models to render the list.
    var data: [Model] { get }

    /// The model that is currently selected in the list.
    var selected: Model? { get }

    /// Called when a different model is selected.
    func handleSelectedChange(selected: Model)

    /// Configures the cell with the given model.
    func configureCell(cell: Cell, model: Model)
}
