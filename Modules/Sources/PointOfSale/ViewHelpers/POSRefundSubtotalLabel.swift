import Foundation
import WooFoundation

enum POSRefundSubtotalLabel {
    static func make(_ count: Int) -> String {
        String.pluralize(count, singular: Localization.singular, plural: Localization.plural)
    }

    private enum Localization {
        static let singular = NSLocalizedString(
            "pos.refundDetailView.itemsSubtotalFormat.singular",
            value: "Items subtotal (%1$d item)",
            comment: "Label for items subtotal row in refund review and detail when there is 1 item. %1$d is the number of items."
        )
        static let plural = NSLocalizedString(
            "pos.refundDetailView.itemsSubtotalFormat.plural",
            value: "Items subtotal (%1$d items)",
            comment: "Label for items subtotal row in refund review and detail when there are multiple items. %1$d is the number of items."
        )
    }
}
