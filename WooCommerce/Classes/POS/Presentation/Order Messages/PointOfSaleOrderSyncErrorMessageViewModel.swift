import SwiftUI

final class PointOfSaleOrderSyncErrorMessageViewModel: ObservableObject {
    struct ActionModel {
        let title: String = Localization.actionTitle
        let handler: () -> Void

        init(handler: @escaping () -> Void) {
            self.handler = handler
        }
    }

    let title: String = Localization.title
    let message: String
    let actionModel: ActionModel

    init(message: String, handler: @escaping () -> Void) {
        self.message = message
        self.actionModel = .init(handler: handler)
    }
}

private extension PointOfSaleOrderSyncErrorMessageViewModel {
    enum Localization {
        static let title = NSLocalizedString(
            "pointOfSale.orderSync.error.title",
            value: "Couldn't load totals",
            comment: "Title of the error when failing to synchronize order and calculate order totals"
        )

        static let actionTitle = NSLocalizedString(
            "pointOfSale.orderSync.error.retry",
            value: "Retry",
            comment: "Button title to retry synchronizing order and calculating order totals"
        )
    }
}
