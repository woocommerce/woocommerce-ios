import Foundation
import Storage

struct MockRefundActionHandler: MockActionHandler {

    typealias ActionType = RefundAction

    let objectGraph: MockObjectGraph
    let storageManager: StorageManagerType

    func handle(action: ActionType) {
        switch action {

            /// Not implemented yet
            case .retrieveRefunds(_, _, _, _, let onCompletion):
                success(onCompletion)
            case .previewRefund(let siteID, let orderID, let lineItems, let onCompletion):
                previewRefund(siteID: siteID, orderID: orderID, lineItems: lineItems, onCompletion: onCompletion)
            case .createRefundV4(let siteID, let orderID, let reason, let automaticRefund, _, let lineItems, let onCompletion):
                createRefundV4(siteID: siteID,
                               orderID: orderID,
                               reason: reason,
                               automaticRefund: automaticRefund,
                               lineItems: lineItems,
                               onCompletion: onCompletion)

            default: unimplementedAction(action: action)
        }
    }
}

private extension MockRefundActionHandler {

    func previewRefund(siteID: Int64,
                       orderID: Int64,
                       lineItems: [RefundV4LineItem],
                       onCompletion: (Result<RefundPreview, Error>) -> Void) {
        let order = objectGraph.order(forSiteId: siteID, orderId: orderID)
        let subtotal = lineItems.reduce(Decimal.zero) { runningTotal, lineItem in
            if let refundTotal = lineItem.refundTotal {
                return runningTotal + refundTotal
            }
            let unitPrice = order?.items.first { $0.itemID == lineItem.lineItemID }?.price.decimalValue ?? .zero
            return runningTotal + unitPrice * (lineItem.quantity ?? .zero)
        }
        let emptySection = RefundPreview.Section(items: [], subtotal: .zero, tax: .zero, total: .zero)
        let preview = RefundPreview(subtotal: subtotal,
                                    tax: .zero,
                                    total: subtotal,
                                    maxRefundable: subtotal,
                                    breakdown: .init(products: emptySection, shipping: emptySection, fees: emptySection))
        onCompletion(.success(preview))
    }

    func createRefundV4(siteID: Int64,
                        orderID: Int64,
                        reason: String,
                        automaticRefund: Bool,
                        lineItems: [RefundV4LineItem],
                        onCompletion: (Result<Refund, Error>) -> Void) {
        previewRefund(siteID: siteID, orderID: orderID, lineItems: lineItems) { previewResult in
            let amount: Decimal
            switch previewResult {
            case .success(let preview):
                amount = preview.total
            case .failure:
                amount = .zero
            }
            let refund = Refund(refundID: 1,
                                orderID: orderID,
                                siteID: siteID,
                                dateCreated: Date(),
                                amount: NSDecimalNumber(decimal: amount).stringValue,
                                reason: reason,
                                refundedByUserID: 0,
                                isAutomated: automaticRefund,
                                createAutomated: automaticRefund,
                                items: [],
                                shippingLines: [])
            onCompletion(.success(refund))
        }
    }
}
