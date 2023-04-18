import Yosemite

/// Represents the product types available when creating or editing products.
/// This includes the remote `ProductType`, whether the product type is virtual, and strings/images shown in the bottom sheet.
///
public enum BottomSheetProductType: Hashable {
    case simple(isVirtual: Bool)
    case grouped
    case affiliate
    case variable
    case custom(String) // in case there are extensions modifying product types
    case blank // used to create a simple product without a template

    /// Remote ProductType
    ///
    var productType: ProductType {
        switch self {
        case .simple, .blank:
            return .simple
        case .variable:
            return .variable
        case .grouped:
            return .grouped
        case .affiliate:
            return .affiliate
        case .custom(let title):
            return .custom(title)
        }
    }

    /// Whether product is virtual
    ///
    var isVirtual: Bool {
        switch self {
        case .simple(let isVirtual):
            return isVirtual
        default:
            return false
        }
    }

    /// Title shown on the action sheet.
    ///
    var actionSheetTitle: String {
        let simplifyProductEditingEnabled = ServiceLocator.featureFlagService.isFeatureFlagEnabled(.simplifyProductEditing)
        switch self {
        case .simple(let isVirtual):
            if isVirtual, simplifyProductEditingEnabled {
                return NSLocalizedString("Virtual product",
                                         comment: "Action sheet option when the user wants to change the Product type to simple virtual product")
            } else if !isVirtual, simplifyProductEditingEnabled {
                return NSLocalizedString("Physical product",
                                         comment: "Action sheet option when the user wants to change the Product type to simple physical product")
            } else if isVirtual {
                return NSLocalizedString("Simple virtual product",
                                         comment: "Action sheet option when the user wants to change the Product type to simple virtual product")
            } else {
                return NSLocalizedString("Simple physical product",
                                         comment: "Action sheet option when the user wants to change the Product type to simple physical product")
            }
        case .variable:
            return NSLocalizedString("Variable product",
                                     comment: "Action sheet option when the user wants to change the Product type to varible product")
        case .grouped:
            return NSLocalizedString("Grouped product",
                                     comment: "Action sheet option when the user wants to change the Product type to grouped product")
        case .affiliate:
            return NSLocalizedString("External product",
                                     comment: "Action sheet option when the user wants to change the Product type to external product")
        case .custom(let title):
            return title
        case .blank:
            return NSLocalizedString("Blank",
                                     comment: "Action sheet option when the user wants to create a product manually")
        }
    }

    /// Description shown on the action sheet.
    ///
    var actionSheetDescription: String {
        let simplifyProductEditingEnabled = ServiceLocator.featureFlagService.isFeatureFlagEnabled(.simplifyProductEditing)
        switch self {
        case .simple(let isVirtual):
            if isVirtual, simplifyProductEditingEnabled {
                return NSLocalizedString("A digital product like services, downloadable books, music or videos",
                                         comment: "Description of the Action sheet option when the user wants to change the Product type to virtual product")
            } else if !isVirtual, simplifyProductEditingEnabled {
                return NSLocalizedString("A tangible item that gets delivered to customers",
                                         comment: "Description of the Action sheet option when the user wants to change the Product type to physical product")
            } else if isVirtual {
                return NSLocalizedString("A unique digital product like services, downloadable books, music or videos",
                                    comment: "Description of the Action sheet option when the user wants to change the Product type to simple virtual product")
            } else {
                return NSLocalizedString("A unique physical product that you may have to ship to the customer",
                                    comment: "Description of the Action sheet option when the user wants to change the Product type to simple physical product")
            }
        case .variable:
            return NSLocalizedString("A product with variations like color or size",
                                     comment: "Description of the Action sheet option when the user wants to change the Product type to variable product")
        case .grouped:
            return NSLocalizedString("A collection of related products",
                                     comment: "Description of the Action sheet option when the user wants to change the Product type to grouped product")
        case .affiliate:
            return NSLocalizedString("Link a product to an external website",
                                     comment: "Description of the Action sheet option when the user wants to change the Product type to external product")
        case .custom(let title):
            return title
        case .blank:
            return NSLocalizedString("Add a product manually",
                                     comment: "Description of the Action sheet option when the user wants to create a product manually")
        }
    }

    /// Image shown on the action sheet.
    ///
    var actionSheetImage: UIImage {
        switch self {
        case .simple(let isVirtual):
            if isVirtual {
                return UIImage.cloudOutlineImage
            } else {
                return UIImage.productImage
            }
        case .variable:
            return UIImage.variationsImage
        case .grouped:
            return UIImage.widgetsImage
        case .affiliate:
            return UIImage.externalProductImage
        case .custom:
            return UIImage.productImage
        case .blank:
            return UIImage.blankProductImage
        }
    }

    init(productType: ProductType, isVirtual: Bool) {
        switch productType {
        case .simple:
            self = .simple(isVirtual: isVirtual)
        case .variable:
            self = .variable
        case .affiliate:
            self = .affiliate
        case .grouped:
            self = .grouped
        case .subscription:
            // We do not yet support product editing or creation for subscriptions
            self = .custom("subscription")
        case .variableSubscription:
            // We do not yet support product editing or creation for variable subscriptions
            self = .custom("variable-subscription")
        case .bundle:
            // We do not yet support product editing or creation for bundles
            self = .custom("bundle")
        case .composite:
            // We do not yet support product editing or creation for composites
            self = .custom("composite")
        case .custom(let string):
            self = .custom(string)
        }
    }
}

/// `BottomSheetListSelectorCommand` for selecting a product type for the selected Product.
///
final class ProductTypeBottomSheetListSelectorCommand: BottomSheetListSelectorCommand {
    typealias Model = BottomSheetProductType
    typealias Cell = ImageAndTitleAndTextTableViewCell

    var data: [BottomSheetProductType] = [
        .simple(isVirtual: false),
        .simple(isVirtual: true),
        .variable,
        .grouped,
        .affiliate
    ]

    var selected: BottomSheetProductType? = nil

    private let onSelection: (BottomSheetProductType) -> Void

    init(selected: BottomSheetProductType?, onSelection: @escaping (BottomSheetProductType) -> Void) {
        self.onSelection = onSelection

        /// Remove from `data` the selected product type, so that it is not shown in the list.
        data.removeAll { (productType) -> Bool in
            productType == selected
        }
    }

    func configureCell(cell: ImageAndTitleAndTextTableViewCell, model: BottomSheetProductType) {
        let viewModel = ImageAndTitleAndTextTableViewCell.ViewModel(title: model.actionSheetTitle,
                                                                    text: model.actionSheetDescription,
                                                                    image: model.actionSheetImage,
                                                                    imageTintColor: .gray(.shade20),
                                                                    numberOfLinesForText: 0)
        cell.updateUI(viewModel: viewModel)
    }

    func handleSelectedChange(selected: BottomSheetProductType) {
        onSelection(selected)
    }

    func isSelected(model: BottomSheetProductType) -> Bool {
        return model == selected
    }
}
