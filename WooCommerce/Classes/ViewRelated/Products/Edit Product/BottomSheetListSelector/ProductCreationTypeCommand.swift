import Foundation
import UIKit

/// Type to allow merchant to create a template product.
///
public enum ProductCreationType: Equatable {
    case template
    case manual

    /// Title shown on the action sheet.
    ///
    var actionSheetTitle: String {
        switch self {
        case .template:
            return NSLocalizedString("Start with a template", comment: "Title for the option to create a template product")
        case .manual:
            return NSLocalizedString("Add manually", comment: "Title for the option to create product manually")
        }
    }

    /// Description shown on the action sheet.
    ///
    var actionSheetDescription: String {
        switch self {
        case .template:
            return NSLocalizedString("Use a template to create physical, virtual, and variable products. You can edit it as you go.",
                                     comment: "Description for the option to create a template product")
        case .manual:
            return NSLocalizedString("Add a product manually.",
                                     comment: "Description for the option to create product manually")
        }
    }

    /// Image shown on the action sheet.
    ///
    var actionSheetImage: UIImage {
        switch self {
        case .template:
            return .sitesImage
        case .manual:
            return .addOutlineImage
        }
    }
}

/// Selector command for selecting a template product.
///
final class ProductCreationTypeSelectorCommand: BottomSheetListSelectorCommand {
    typealias Model = ProductCreationType
    typealias Cell = ImageAndTitleAndTextTableViewCell

    var data: [ProductCreationType] = [.template, .manual]

    var selected: ProductCreationType? = nil

    private let onSelection: (ProductCreationType) -> Void

    init(onSelection: @escaping (ProductCreationType) -> Void) {
        self.onSelection = onSelection
    }

    func configureCell(cell: ImageAndTitleAndTextTableViewCell, model: ProductCreationType) {
        let viewModel = ImageAndTitleAndTextTableViewCell.ViewModel(title: model.actionSheetTitle,
                                                                    text: model.actionSheetDescription,
                                                                    image: model.actionSheetImage,
                                                                    imageTintColor: .gray(.shade20),
                                                                    numberOfLinesForText: 0)
        cell.updateUI(viewModel: viewModel)
    }

    func handleSelectedChange(selected: ProductCreationType) {
        onSelection(selected)
    }

    func isSelected(model: ProductCreationType) -> Bool {
        return model == selected
    }
}
