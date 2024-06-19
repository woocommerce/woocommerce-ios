import Foundation
import Yosemite

/// Represents the product types available when creating or editing products.
/// This includes the remote `ProductType`, whether the product type is virtual, and strings/images shown in the bottom sheet.
///
public enum BottomSheetProductType: Hashable, Identifiable {

    case simple(isVirtual: Bool)
    case grouped
    case affiliate
    case variable
    case subscription
    case variableSubscription
    case custom(String) // in case there are extensions modifying product types
    case blank // used to create a simple product without a template

    // Identifiable conformance
    public var id: String {
        switch self {
        case .simple(let isVirtual):
            return isVirtual ? "simpleVirtual" : "simple"
        case .grouped:
            return "grouped"
        case .affiliate:
            return "affiliate"
        case .variable:
            return "variable"
        case .subscription:
            return "subscription"
        case .variableSubscription:
            return "variableSubscription"
        case .custom(let title):
            return "custom" + title
        case .blank:
            return "blank"
        }
    }

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
        case .subscription:
            return .subscription
        case .variableSubscription:
            return .variableSubscription
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
        switch self {
        case .simple(let isVirtual):
            if isVirtual {
                return NSLocalizedString(
                    "bottomSheetProductType.simpleVirtualProduct.title",
                    value: "Virtual product",
                    comment: "Action sheet option when the user wants to change the Product type to simple virtual product")
            } else {
                return NSLocalizedString(
                    "bottomSheetProductType.simpleProduct.title",
                    value: "Physical product",
                    comment: "Action sheet option when the user wants to change the Product type to simple physical product")
            }
        case .variable:
            return NSLocalizedString(
                "bottomSheetProductType.variable.title",
                value: "Variable product",
                comment: "Action sheet option when the user wants to change the Product type to varible product")
        case .grouped:
            return NSLocalizedString(
                "bottomSheetProductType.grouped.title",
                value: "Grouped product",
                comment: "Action sheet option when the user wants to change the Product type to grouped product")
        case .affiliate:
            return NSLocalizedString(
                "bottomSheetProductType.affiliate.title",
                value: "External product",
                comment: "Action sheet option when the user wants to change the Product type to external product")
        case .custom(let title):
            return title
        case .subscription:
            return NSLocalizedString(
                "bottomSheetProductType.subscriptionProduct.title",
                value: "Simple subscription",
                comment: "Action sheet option when the user wants to change the Product type to Subscription product")
        case .variableSubscription:
            return NSLocalizedString(
                "bottomSheetProductType.variableSubscriptionProduct.title",
                value: "Variable subscription",
                comment: "Action sheet option when the user wants to change the Product type to Variable subscription product")
        case .blank:
            return NSLocalizedString(
                "bottomSheetProductType.blank.title",
                value: "Blank",
                comment: "Action sheet option when the user wants to create a product manually")
        }
    }

    /// Description shown on the action sheet.
    ///
    var actionSheetDescription: String {
        switch self {
        case .simple(let isVirtual):
            if isVirtual {
                return NSLocalizedString(
                    "bottomSheetProductType.simpleVirtual.description",
                    value: "A unique digital product like services, downloadable books, music or videos",
                    comment: "Description of the Action sheet option when the user wants to change the Product type to simple virtual product")
            } else {
                return NSLocalizedString(
                    "bottomSheetProductType.simple.description",
                    value: "A unique physical product that you may have to ship to the customer",
                    comment: "Description of the Action sheet option when the user wants to change the Product type to simple physical product")
            }
        case .variable:
            return NSLocalizedString(
                "bottomSheetProductType.variable.description",
                value: "A product with variations like color or size",
                comment: "Description of the Action sheet option when the user wants to change the Product type to variable product")
        case .grouped:
            return NSLocalizedString(
                "bottomSheetProductType.grouped.description",
                value: "A collection of related products",
                comment: "Description of the Action sheet option when the user wants to change the Product type to grouped product")
        case .affiliate:
            return NSLocalizedString(
                "bottomSheetProductType.affiliate.description",
                value: "Link a product to an external website",
                comment: "Description of the Action sheet option when the user wants to change the Product type to external product")
        case .subscription:
            return NSLocalizedString(
                "bottomSheetProductType.subscription.description",
                value: "A unique product subscription that enables recurring payments",
                comment: "Description of the Action sheet option when the user wants to change the Product type to Subscription product")
        case .variableSubscription:
            return NSLocalizedString(
                "bottomSheetProductType.variableSubscription.description",
                value: "A product subscription with variations",
                comment: "Action sheet option when the user wants to change the Product type to Variable subscription product")
        case .custom(let title):
            return title
        case .blank:
            return NSLocalizedString(
                "bottomSheetProductType.blank.description",
                value: "Add a product manually",
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
        case .subscription:
            return UIImage.subscriptionProductImage
        case .variableSubscription:
            return UIImage.variableSubscriptionProductImage
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
            self = .subscription
        case .variableSubscription:
            self = .variableSubscription
        case .booking:
            // We do not yet support product editing or creation for bookable products
            self = .custom("booking")
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
