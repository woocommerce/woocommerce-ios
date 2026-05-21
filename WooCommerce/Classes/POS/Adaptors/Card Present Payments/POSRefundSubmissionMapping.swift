import Foundation
import PointOfSale
import Yosemite
import WooFoundation

struct POSRefundSubmissionMapping {
    struct PreparedRefundContext {
        let order: Order
        let charge: WCPayCharge?
        let paymentGateway: PaymentGateway?
        let paymentGatewayAccount: PaymentGatewayAccount?
        let refundableItems: [RefundableOrderItem]
        let refundableFees: [OrderFeeLine]
    }

    private let currencyFormatter: CurrencyFormatter

    init(currencyFormatter: CurrencyFormatter) {
        self.currencyFormatter = currencyFormatter
    }

    func normalizedForPOSInteracRefund(charge: WCPayCharge) -> WCPayCharge {
        switch charge.paymentMethodDetails {
        case .cardPresent(let details) where details.brand == .interac:
            return charge.copy(paymentMethodDetails: .interacPresent(details: details))
        default:
            return charge
        }
    }

    func determineRefundableFees(from order: Order, with refunds: [Refund]) -> [OrderFeeLine] {
        let refundedFeeIDs = Set(refunds.flatMap(\.feeLines).map { $0.refundedItemID ?? $0.feeID })
        return order.fees.filter { !refundedFeeIDs.contains($0.feeID) }
    }

    func makeSelectableItems(refundableItems: [RefundableOrderItem],
                             fees: [OrderFeeLine],
                             currency: String) -> [POSRefundSelectableItem] {
        var index = 0
        var selectableItems: [POSRefundSelectableItem] = []

        for refundableItem in refundableItems {
            let item = refundableItem.item
            let lineItemTotal = currencyFormatter.convertToDecimal(item.total) as Decimal? ?? (item.price as Decimal) * item.quantity
            let totalTax = currencyFormatter.convertToDecimal(item.totalTax) as Decimal? ?? .zero
            let formattedPrice = currencyFormatter.formatAmount(item.price, with: currency) ?? ""

            for _ in 0..<refundableItem.quantity {
                selectableItems.append(POSRefundSelectableItem(
                    itemID: item.itemID,
                    name: item.name,
                    imageSrc: item.image?.src,
                    lineItemTotal: lineItemTotal,
                    totalTax: totalTax,
                    originalQuantity: item.quantity,
                    formattedPrice: formattedPrice,
                    attributes: item.attributes,
                    isSelected: true,
                    index: index))
                index += 1
            }
        }

        for fee in fees {
            let total = currencyFormatter.convertToDecimal(fee.total) as Decimal? ?? .zero
            let totalTax = currencyFormatter.convertToDecimal(fee.totalTax) as Decimal? ?? .zero
            selectableItems.append(POSRefundSelectableItem(
                itemID: fee.feeID,
                name: displayName(for: fee),
                imageSrc: nil,
                lineItemTotal: total,
                totalTax: totalTax,
                originalQuantity: 1,
                formattedPrice: currencyFormatter.formatAmount(fee.total, with: currency) ?? "",
                attributes: fee.attributes,
                isLumpSum: true,
                isSelected: true,
                index: index))
            index += 1
        }

        return selectableItems
    }

    func refundComponents(from selectedItems: [POSRefundSelectableItem],
                          context: PreparedRefundContext) -> (items: [RefundableOrderItem], fees: [OrderFeeLine]) {
        let selectedProductQuantities = selectedItems
            .filter { !$0.isLumpSum }
            .reduce(into: [Int64: Int]()) { quantities, item in
                quantities[item.itemID, default: 0] += 1
            }

        let refundItems = context.refundableItems.compactMap { refundableItem -> RefundableOrderItem? in
            guard let quantity = selectedProductQuantities[refundableItem.item.itemID], quantity > 0 else {
                return nil
            }
            return RefundableOrderItem(item: refundableItem.item, quantity: quantity)
        }

        let selectedFeeIDs = Set(selectedItems.filter(\.isLumpSum).map(\.itemID))
        let fees = context.refundableFees.filter { selectedFeeIDs.contains($0.feeID) }

        return (refundItems, fees)
    }

    func refundValues(items: [RefundableOrderItem], fees: [OrderFeeLine]) -> (subtotal: Decimal, tax: Decimal, total: Decimal) {
        let itemValues = RefundItemsValuesCalculationUseCase(refundItems: items, currencyFormatter: currencyFormatter).calculateRefundValues()
        let feeValues = RefundFeesCalculationUseCase(fees: fees, currencyFormatter: currencyFormatter).calculateRefundValues()
        let subtotal = itemValues.subtotal + feeValues.subtotal
        let tax = itemValues.tax + feeValues.tax
        return (subtotal, tax, subtotal + tax)
    }

    func apiAmountString(for amount: Decimal) -> String {
        NSDecimalNumber(decimal: amount).stringValue
    }

    func gatewaySupportsAutomaticRefunds(context: PreparedRefundContext) -> Bool {
        if let paymentGateway = context.paymentGateway {
            return paymentGateway.features.contains(.refunds)
        }
        return context.order.paymentMethodID != PaymentGateway.Constants.cashOnDeliveryGatewayID
    }

    func paymentMethodDescription(for order: Order, charge: WCPayCharge?) -> String {
        let paymentMethod = order.paymentMethodTitle.isEmpty ? Localization.manualPaymentMethod : order.paymentMethodTitle
        switch charge?.paymentMethodDetails {
        case .some(.cardPresent(let details)), .some(.interacPresent(let details)):
            return String(format: Localization.viaCardPaymentMethodFormat,
                          paymentMethod,
                          cardDescription(brand: details.brand, last4: details.last4))
        default:
            return String(format: Localization.viaPaymentMethodFormat, paymentMethod)
        }
    }
}

private extension POSRefundSubmissionMapping {
    func displayName(for fee: OrderFeeLine) -> String {
        let trimmedName = (fee.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? Localization.defaultFeeName : trimmedName
    }

    func cardDescription(brand: WCPayCardBrand, last4: String) -> String {
        brand.refundCardDescription(last4: last4)
    }
}

private enum Localization {
    static let viaPaymentMethodFormat = NSLocalizedString(
        "pos.refundSubmissionAdaptor.paymentMethodDescription.viaPaymentMethod",
        value: "via %@",
        comment: "Payment method description for POS refunds. %@ is the payment method title."
    )

    static let viaCardPaymentMethodFormat = NSLocalizedString(
        "pos.refundSubmissionAdaptor.paymentMethodDescription.viaCardPaymentMethod",
        value: "via %1$@ %2$@",
        comment: "Payment method description for POS refunds. %1$@ is the payment method title, %2$@ is card details."
    )

    static let manualPaymentMethod = NSLocalizedString(
        "pos.refundSubmissionAdaptor.paymentMethodDescription.manualPaymentMethod",
        value: "manual payment",
        comment: "Fallback payment method description for POS refunds when no payment method title is available."
    )

    static let defaultFeeName = NSLocalizedString(
        "pos.refundSubmissionAdaptor.defaultFeeName",
        value: "Custom amount",
        comment: "Fallback name for a custom amount fee line in POS refunds."
    )
}
