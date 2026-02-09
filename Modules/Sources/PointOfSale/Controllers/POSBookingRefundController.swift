// POSBookingRefundController.swift
import Foundation
import Observation
import Yosemite
import Networking
import NetworkingCore
import class WooFoundation.CurrencyFormatter

/// Manages the refund flow for a booking's linked order.
///
/// Fetches the order associated with a booking, converts its line items into selectable items,
/// and uses `POSRefundsServiceProtocol` for amount calculations and refund creation.
/// Follows the same patterns as `POSOrderListController`'s refund methods.
@MainActor
@Observable
final class POSBookingRefundController {
    private(set) var refundSelectableItems: [POSRefundSelectableItem] = []
    private(set) var isLoadingOrder: Bool = false
    private(set) var orderLoadError: Error?

    private let siteID: Int64
    private let orderProvider: POSOrderProviding
    private let refundsService: POSRefundsServiceProtocol
    private let currencyFormatter: CurrencyFormatter

    private var fetchedOrder: Order?

    init(siteID: Int64,
         orderProvider: POSOrderProviding,
         refundsService: POSRefundsServiceProtocol,
         currencyFormatter: CurrencyFormatter) {
        self.siteID = siteID
        self.orderProvider = orderProvider
        self.refundsService = refundsService
        self.currencyFormatter = currencyFormatter
    }

    /// Fetches the order for a booking and prepares selectable items for the refund flow.
    func loadOrderForRefund(booking: POSBooking) async {
        guard let orderID = booking.orderID else {
            orderLoadError = BookingRefundError.noLinkedOrder
            return
        }

        isLoadingOrder = true
        orderLoadError = nil

        do {
            let order = try await orderProvider.fetchOrder(siteID: siteID, orderID: orderID)
            fetchedOrder = order
            refundSelectableItems = createSelectableItems(from: order)
        } catch {
            orderLoadError = error
        }

        isLoadingOrder = false
    }

    /// Whether the loaded order is already fully refunded.
    var isFullyRefunded: Bool {
        fetchedOrder?.status == .refunded
    }

    /// Whether the payment gateway likely supports automatic refunds.
    /// Returns `false` when no gateway is associated (e.g. order manually marked as completed).
    var supportsAutomaticRefund: Bool {
        guard let order = fetchedOrder else { return false }
        let methodID = order.paymentMethodID
        return !methodID.isEmpty && methodID != PaymentGateway.Constants.cashOnDeliveryGatewayID
    }

    /// A human-readable description of the payment method (e.g. "via Credit Card").
    var paymentMethodDescription: String {
        guard let order = fetchedOrder else { return "" }
        let title = order.paymentMethodTitle
        if title.isEmpty {
            return ""
        }
        return String(format: Localization.viaPaymentMethod, title)
    }

    // MARK: - Item Selection

    func toggleRefundItemSelection(at index: Int) {
        guard refundSelectableItems.indices.contains(index) else { return }
        refundSelectableItems[index].isSelected.toggle()
    }

    func toggleAllRefundItemsSelection() {
        let allSelected = !refundSelectableItems.isEmpty && refundSelectableItems.allSatisfy(\.isSelected)
        let newSelectionState = !allSelected
        for index in refundSelectableItems.indices {
            refundSelectableItems[index].isSelected = newSelectionState
        }
    }

    func clearRefundSelection() {
        refundSelectableItems = []
        fetchedOrder = nil
    }

    // MARK: - Refund Data Preparation

    func preparePOSRefundReviewData() -> POSRefundReviewData? {
        let selectedItems = refundSelectableItems.filter(\.isSelected)
        guard !selectedItems.isEmpty else { return nil }

        let refundableItems = selectedItems.map {
            POSRefundableItem(
                itemID: $0.itemID,
                lineItemTotal: $0.lineItemTotal,
                totalTax: $0.totalTax,
                originalQuantity: $0.originalQuantity
            )
        }

        let amounts = refundsService.calculateRefundAmounts(for: refundableItems)

        guard let formattedSubtotal = currencyFormatter.formatAmount(amounts.subtotal),
              let formattedTax = currencyFormatter.formatAmount(amounts.tax),
              let formattedTotal = currencyFormatter.formatAmount(amounts.total) else {
            return nil
        }

        return POSRefundReviewData(
            itemsCount: selectedItems.count,
            formattedItemsSubtotal: formattedSubtotal,
            formattedTax: formattedTax,
            formattedRefundTotal: formattedTotal,
            paymentMethodDescription: paymentMethodDescription,
            refundReason: nil
        )
    }

    // MARK: - Process Refund

    func processRefund(reason: String?) async throws {
        guard let order = fetchedOrder else {
            throw BookingRefundError.noOrderLoaded
        }

        let selectedItems = refundSelectableItems.filter(\.isSelected)
        guard !selectedItems.isEmpty else {
            throw BookingRefundError.noItemsSelected
        }

        let refundableItems = selectedItems.map {
            POSRefundableItem(
                itemID: $0.itemID,
                lineItemTotal: $0.lineItemTotal,
                totalTax: $0.totalTax,
                originalQuantity: $0.originalQuantity
            )
        }

        try await refundsService.createRefund(
            orderID: order.orderID,
            items: refundableItems,
            reason: reason,
            isAutomaticRefund: supportsAutomaticRefund
        )

        clearRefundSelection()
    }

    // MARK: - Private Helpers

    private func createSelectableItems(from order: Order) -> [POSRefundSelectableItem] {
        order.items.flatMap { item -> [POSRefundSelectableItem] in
            let intQuantity = NSDecimalNumber(decimal: item.quantity).intValue
            guard intQuantity > 0 else { return [] }

            let lineItemTotal = Decimal(string: item.total) ?? 0
            let totalTax = Decimal(string: item.totalTax) ?? 0
            let formattedPrice = currencyFormatter.formatAmount(item.price.decimalValue) ?? item.total

            return (0..<intQuantity).map { index in
                POSRefundSelectableItem(
                    itemID: item.itemID,
                    name: item.name,
                    imageSrc: item.image?.src,
                    lineItemTotal: lineItemTotal,
                    totalTax: totalTax,
                    originalQuantity: item.quantity,
                    formattedPrice: formattedPrice,
                    attributes: item.attributes,
                    isSelected: true,
                    index: index
                )
            }
        }
    }

    // MARK: - Localization

    private enum Localization {
        static let viaPaymentMethod = NSLocalizedString(
            "posBookingRefundController.viaPaymentMethod",
            value: "via %@",
            comment: "Payment method description for refund review. %@ is the payment method title (e.g. 'Credit Card')."
        )
    }
}

// MARK: - Errors

enum BookingRefundError: LocalizedError {
    case noLinkedOrder
    case noOrderLoaded
    case noItemsSelected

    var errorDescription: String? {
        switch self {
        case .noLinkedOrder:
            return NSLocalizedString(
                "bookingRefundError.noLinkedOrder",
                value: "This booking has no linked order to refund.",
                comment: "Error when trying to refund a booking without a linked order"
            )
        case .noOrderLoaded:
            return NSLocalizedString(
                "bookingRefundError.noOrderLoaded",
                value: "Order data has not been loaded yet.",
                comment: "Error when trying to process refund before loading the order"
            )
        case .noItemsSelected:
            return NSLocalizedString(
                "bookingRefundError.noItemsSelected",
                value: "No items selected for refund.",
                comment: "Error when trying to process refund with no items selected"
            )
        }
    }
}
