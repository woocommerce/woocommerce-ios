import Foundation
@testable import PointOfSale
import struct Yosemite.POSOrder

/// Supplies fixed preparation and review fixtures. Refund eligibility, arithmetic, and
/// formatting belong to the production app adaptor and must not be reimplemented here.
final class MockPOSRefundSubmissionProcessor: POSRefundSubmissionProcessing {
    let stateModel = POSRefundSubmissionModel()

    var preparationToReturn = POSRefundPreparation(orderID: 1,
                                                    selectableItems: [],
                                                    paymentMethodDescription: "via Cash",
                                                    customerEmail: nil)
    var reviewDataToReturn = POSRefundReviewData(itemsCount: 1,
                                                formattedItemsSubtotal: "$3.00",
                                                formattedTax: "$0.51",
                                                formattedRefundTotal: "$3.51",
                                                paymentMethodDescription: "via Cash",
                                                customerEmail: nil,
                                                refundReason: nil,
                                                isFullRefund: true,
                                                calculationFlow: .local)
    var requiresCardPresentRefund = false
    var prepareRefundErrorToThrow: Error?
    var prepareReviewDataErrorToThrow: Error?
    var submitRefundErrorToThrow: Error?
    var onPrepareReviewDataCalled: (@MainActor () async -> Void)?
    var onSubmitRefund: (@MainActor () async -> Void)?

    private(set) var spyReviewSelectedItems: [POSRefundSelectableItem]?
    private(set) var spyReviewOrderID: Int64?
    private(set) var spyReviewReason: String?

    private(set) var preloadedOrderIDs: [Int64] = []
    private(set) var submitRefundCalled = false
    private(set) var submitRefundCallCount = 0
    private(set) var spySubmitRefundOrderID: Int64?
    private(set) var spySubmitRefundItems: [POSRefundSelectableItem]?
    private(set) var spySubmitRefundReason: String?

    nonisolated init() {}

    func preloadRefund(for order: POSOrder) async {
        preloadedOrderIDs.append(order.id)
    }

    func prepareRefund(for order: POSOrder) async throws -> POSRefundPreparation {
        if let prepareRefundErrorToThrow {
            throw prepareRefundErrorToThrow
        }
        return preparationToReturn
    }

    func prepareReviewData(for order: POSOrder,
                           preparation: POSRefundPreparation,
                           selectedItems: [POSRefundSelectableItem],
                           reason: String?) async throws -> POSRefundReviewData {
        spyReviewSelectedItems = selectedItems
        spyReviewOrderID = order.id
        spyReviewReason = reason
        await onPrepareReviewDataCalled?()
        if let prepareReviewDataErrorToThrow {
            throw prepareReviewDataErrorToThrow
        }
        return reviewDataToReturn
    }

    func submitRefund(for order: POSOrder,
                      preparation: POSRefundPreparation,
                      selectedItems: [POSRefundSelectableItem],
                      reason: String?) async throws {
        submitRefundCalled = true
        submitRefundCallCount += 1
        spySubmitRefundOrderID = order.id
        spySubmitRefundItems = selectedItems
        spySubmitRefundReason = reason
        await onSubmitRefund?()
        if let submitRefundErrorToThrow {
            throw submitRefundErrorToThrow
        }
        stateModel.state = .completed
    }
}
