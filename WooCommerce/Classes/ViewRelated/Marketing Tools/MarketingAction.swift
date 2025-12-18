import Foundation

struct MarketingAction: Identifiable, Equatable {
    let id: String
    let eventID: String
    let type: ActionType

    var name: String {
        type.displayName
    }

    var description: String {
        type.description
    }

    var iconName: String {
        type.iconName
    }

    enum ActionType: String, CaseIterable {
        case editProduct = "edit_product"
        case createCoupon = "create_coupon"

        var displayName: String {
            switch self {
            case .editProduct:
                return NSLocalizedString(
                    "marketingAction.editProduct",
                    value: "Edit Products",
                    comment: "Action to edit products for a marketing event"
                )
            case .createCoupon:
                return NSLocalizedString(
                    "marketingAction.createCoupon",
                    value: "Create Coupon",
                    comment: "Action to create a coupon for a marketing event"
                )
            }
        }

        var description: String {
            switch self {
            case .editProduct:
                return NSLocalizedString(
                    "marketingAction.editProductDescription",
                    value: "Update pricing and featured products for your event",
                    comment: "Description for edit products action"
                )
            case .createCoupon:
                return NSLocalizedString(
                    "marketingAction.createCouponDescription",
                    value: "Create special discount codes for customers",
                    comment: "Description for create coupon action"
                )
            }
        }

        var iconName: String {
            switch self {
            case .editProduct:
                return "tag"
            case .createCoupon:
                return "ticket"
            }
        }
    }

    /// Creates all available actions for a given event
    static func availableActions(for event: MarketingEvent) -> [MarketingAction] {
        ActionType.allCases.map { type in
            MarketingAction(
                id: "\(event.id)-\(type.rawValue)",
                eventID: event.id,
                type: type
            )
        }
    }
}
