import Foundation
@testable import PointOfSale
import struct Yosemite.POSOrder
@testable import struct Yosemite.POSRefundsResult
import class WooFoundation.CurrencyFormatter

final class MockPOSRefundSubmissionProcessor: POSRefundSubmissionProcessing {
    let stateModel = POSRefundSubmissionModel()

    nonisolated(unsafe) private let refundsService: MockPOSRefundsService
    nonisolated(unsafe) private let currencyFormatter: CurrencyFormatter
    private var refundResultsByOrderID: [Int64: POSRefundsResult] = [:]
    var requiresCardPresentRefund = false
    var shouldSuspendSubmitRefund = false
    var onSubmitRefundStarted: (() -> Void)?
    private var submitRefundContinuation: CheckedContinuation<Void, Never>?

    private(set) var submitRefundCalled = false
    private(set) var spySubmitRefundOrderID: Int64?
    private(set) var spySubmitRefundItems: [POSRefundSelectableItem]?
    private(set) var spySubmitRefundReason: String?
    private(set) var spySubmitRefundIsAutomaticRefund: Bool?
    var submitRefundErrorToThrow: Error?

    nonisolated init(refundsService: MockPOSRefundsService,
                     currencyFormatter: CurrencyFormatter) {
        self.refundsService = refundsService
        self.currencyFormatter = currencyFormatter
    }

    private(set) var preloadedOrderIDs: [Int64] = []
    var prepareRefundErrorToThrow: Error?

    func preloadRefund(for order: POSOrder) async {
        preloadedOrderIDs.append(order.id)
    }

    func prepareRefund(for order: POSOrder) async throws -> POSRefundPreparation {
        if let prepareRefundErrorToThrow {
            throw prepareRefundErrorToThrow
        }
        let refundsResult = try await refundsService.providePointOfSaleRefunds(for: order)
        refundResultsByOrderID[order.id] = refundsResult

        let refundedQuantitiesByItemID = refundsResult.refunds.flatMap(\.items).refundedQuantitiesByItemID()
        let productSelectables = order.lineItems.flatMap { item -> [POSRefundSelectableItem] in
            let originalQuantity = NSDecimalNumber(decimal: item.quantity).intValue
            let refundedQuantity = refundedQuantitiesByItemID[item.itemID] ?? 0
            let availableQuantity = originalQuantity - refundedQuantity
            guard availableQuantity > 0 else { return [] }

            return (0..<availableQuantity).map { index in
                POSRefundSelectableItem(from: item, isSelected: true, index: index)
            }
        }

        let alreadyRefundedItemIDs = Set(refundsResult.refunds.flatMap(\.items).compactMap(\.refundedItemID))
        let feeSelectables = order.customAmounts
            .filter { !alreadyRefundedItemIDs.contains($0.id) }
            .map { POSRefundSelectableItem(from: $0, isSelected: true) }

        return POSRefundPreparation(
            orderID: order.id,
            selectableItems: productSelectables + feeSelectables,
            paymentMethodDescription: String(format: "via %1$@", order.paymentMethodTitle),
            customerEmail: order.customerEmail,
            requiresCardPresentRefund: requiresCardPresentRefund
        )
    }

    var prepareReviewDataErrorToThrow: Error?
    var onPrepareReviewDataCalled: (@MainActor () async -> Void)?

    func prepareReviewData(for order: POSOrder,
                           preparation: POSRefundPreparation,
                           selectedItems: [POSRefundSelectableItem],
                           reason: String?) async throws -> POSRefundReviewData {
        await onPrepareReviewDataCalled?()
        if let error = prepareReviewDataErrorToThrow {
            throw error
        }

        let amounts = reviewAmounts(for: selectedItems)
        return POSRefundReviewData(
            itemsCount: selectedItems.count,
            formattedItemsSubtotal: currencyFormatter.formatAmount(amounts.subtotal) ?? "",
            formattedTax: currencyFormatter.formatAmount(amounts.tax) ?? "",
            formattedRefundTotal: currencyFormatter.formatAmount(amounts.subtotal + amounts.tax) ?? "",
            paymentMethodDescription: preparation.paymentMethodDescription,
            customerEmail: preparation.customerEmail,
            refundReason: reason,
            isFullRefund: selectedItems.count == preparation.selectableItems.count,
            calculationFlow: .local
        )
    }

    func submitRefund(for order: POSOrder,
                      preparation: POSRefundPreparation,
                      selectedItems: [POSRefundSelectableItem],
                      reason: String?) async throws {
        onSubmitRefundStarted?()
        if shouldSuspendSubmitRefund {
            await withCheckedContinuation { continuation in
                submitRefundContinuation = continuation
            }
        }

        submitRefundCalled = true
        spySubmitRefundOrderID = order.id
        spySubmitRefundItems = selectedItems
        spySubmitRefundReason = reason
        spySubmitRefundIsAutomaticRefund = refundResultsByOrderID[preparation.orderID]?.supportsAutomaticRefund ?? true

        if let error = submitRefundErrorToThrow {
            throw error
        }

        stateModel.state = .completed
    }

    private func reviewAmounts(for items: [POSRefundSelectableItem]) -> (subtotal: Decimal, tax: Decimal) {
        let groupedItems = Dictionary(grouping: items, by: \.itemID)
        return groupedItems.values.reduce((subtotal: Decimal.zero, tax: Decimal.zero)) { result, items in
            let subtotal = calculateAmount(for: items, keyPath: \.lineItemTotal)
            let tax = calculateAmount(for: items, keyPath: \.totalTax)
            return (result.subtotal + subtotal, result.tax + tax)
        }
    }

    private func calculateAmount(for items: [POSRefundSelectableItem], keyPath: KeyPath<POSRefundSelectableItem, Decimal>) -> Decimal {
        guard let firstItem = items.first, firstItem.originalQuantity > 0 else {
            return .zero
        }

        if firstItem.isLumpSum || Decimal(items.count) == firstItem.originalQuantity {
            return firstItem[keyPath: keyPath]
        }

        return (firstItem[keyPath: keyPath] / firstItem.originalQuantity) * Decimal(items.count)
    }

    func resumeSubmitRefund() {
        shouldSuspendSubmitRefund = false
        submitRefundContinuation?.resume()
        submitRefundContinuation = nil
    }
}
