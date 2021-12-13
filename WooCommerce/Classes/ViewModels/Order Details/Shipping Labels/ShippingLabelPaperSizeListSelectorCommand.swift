import Foundation
import enum Yosemite.ShippingLabelPaperSize

/// Command to populate the shipping label paper size list selector
///
final class ShippingLabelPaperSizeListSelectorCommand: ListSelectorCommand {
    typealias Model = ShippingLabelPaperSize
    typealias Cell = BasicTableViewCell

    /// Data to display
    ///
    let data: [ShippingLabelPaperSize]

    /// Holds the current selected state
    ///
    private(set) var selected: ShippingLabelPaperSize?

    /// Navigation bar title
    ///
    let navigationBarTitle: String? = Localization.navigationBarTitle

    func handleSelectedChange(selected: ShippingLabelPaperSize, viewController: ViewController) {
        self.selected = selected
    }

    func isSelected(model: ShippingLabelPaperSize) -> Bool {
        selected == model
    }

    func configureCell(cell: BasicTableViewCell, model: ShippingLabelPaperSize) {
        cell.textLabel?.text = model.description
    }

    init(paperSizeOptions: [ShippingLabelPaperSize], selected: ShippingLabelPaperSize?) {
        self.data = paperSizeOptions
        self.selected = selected
    }
}

// MARK: Constants
private extension ShippingLabelPaperSizeListSelectorCommand {
    enum Localization {
        static let navigationBarTitle = NSLocalizedString("Choose Paper Size", comment: "Navigation title on the shipping label paper size selector screen")
    }
}
