import Foundation
import Yosemite

extension OrderStore.GiftCardError {
    /// Title of the error notice in order form.
    var noticeTitle: String {
        switch self {
            case .cannotApply:
                return Localization.Notice.cannotApplyTitle
            case .invalid:
                return Localization.Notice.invalidTitle
            case .notApplied:
                return Localization.Notice.notAppliedTitle
        }
    }

    /// Message of the error notice in order form.
    var noticeMessage: String {
        switch self {
            case let .cannotApply(reason):
                return reason ?? Localization.Notice.cannotApplyMessage
            case let .invalid(reason):
                return reason ?? Localization.Notice.invalidMessage
            case .notApplied:
                return Localization.Notice.notAppliedMessage
        }
    }
}

extension OrderStore.GiftCardError: CustomStringConvertible {
    public var description: String {
        switch self {
            case let .cannotApply(reason):
                return String.localizedStringWithFormat(Localization.Description.cannotApplyFormat, reason ?? "")
            case let .invalid(reason):
                return String.localizedStringWithFormat(Localization.Description.invalidFormat, reason ?? "")
            case .notApplied:
                return Localization.Description.notApplied
        }
    }
}

private extension OrderStore.GiftCardError {
    enum Localization {
        enum Description {
            static let cannotApplyFormat = NSLocalizedString(
                "Cannot apply gift card to order error: %1$@",
                comment: "Order gift card error thrown when the gift card cannot be applied. %1$@ is the detailed reason."
            )
            static let invalidFormat = NSLocalizedString(
                "Invalid gift card error: %1$@",
                comment: "Order gift card error thrown when the gift card is invalid. %1$@ is the detailed reason."
            )
            static let notApplied = NSLocalizedString(
                "The gift card is not applied.",
                comment: "Order gift card error thrown when the gift card is not applied."
            )
        }

        enum Notice {
            static let cannotApplyTitle = NSLocalizedString(
                "Cannot apply gift card to order",
                comment: "Order gift card error notice title when the gift card cannot be applied."
            )
            static let invalidTitle = NSLocalizedString(
                "Gift card is invalid",
                comment: "Order gift card error notice title when the gift card is invalid."
            )
            static let notAppliedTitle = NSLocalizedString(
                "Gift card is not applied",
                comment: "Order gift card error notice title when the gift card is invalid."
            )
            static let cannotApplyMessage = NSLocalizedString(
                "Cannot apply gift card to order",
                comment: "Order gift card error notice message when the gift card cannot be applied."
            )
            static let invalidMessage = NSLocalizedString(
                "Gift card is invalid",
                comment: "Order gift card error notice message when the gift card is invalid."
            )
            static let notAppliedMessage = NSLocalizedString(
                "Please check the remaining balance of the gift card.",
                comment: "Order gift card error notice message when the gift card is invalid."
            )
        }
    }
}
