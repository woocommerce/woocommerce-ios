import SwiftUI
import Combine
import protocol Yosemite.POSItem

final class CartViewModel: CartViewModelProtocol {
    let posModel: PointOfSaleAggregateModel

    init(posModel: PointOfSaleAggregateModel) {
        self.posModel = posModel
    }

    var itemsInCartLabel: String? {
        let itemsCount = posModel.cart.count
        guard itemsCount > 0 else {
            return nil
        }
        return String.pluralize(itemsCount,
                                singular: "%1$d item",
                                plural: "%1$d items")
    }

    func shouldPreventCartEditing(posModel: PointOfSaleAggregateModel) -> Bool {
        guard posModel.paymentState.allowsCartEditing else {
            return true
        }
        return posModel.orderState.isSyncing
    }
}



private extension PointOfSalePaymentState {
    var allowsCartEditing: Bool {
        switch self {
        case .processingPayment,
                .paymentError,
                .cardPaymentSuccessful,
                .validatingOrder,
                .preparingReader:
            return false
        case .idle, .validatingOrderError, .acceptingCard:
            return true
        }
    }
}
