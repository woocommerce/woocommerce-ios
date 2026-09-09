import Foundation
@testable import PointOfSale
import struct Yosemite.POSOrder
import struct Yosemite.POSOrderItem
import struct Yosemite.POSOrderCustomAmount
import struct Yosemite.POSOrderRefund
import enum Yosemite.OrderStatusEnum
import typealias Yosemite.OrderItemAttribute

func makeOrder(id: Int64 = 1,
               status: OrderStatusEnum = .completed,
               paymentMethodID: String = "woocommerce_payments",
               paymentMethodTitle: String = "cod",
               lineItems: [POSOrderItem] = [],
               customAmounts: [POSOrderCustomAmount] = [],
               refunds: [POSOrderRefund] = []) -> POSOrder {
    POSOrder(
        id: id,
        number: "\(id)",
        dateCreated: Date(),
        status: status,
        formattedTotal: "$25.99",
        formattedSubtotal: "$25.99",
        customerEmail: "customer1@example.com",
        paymentMethodID: paymentMethodID,
        paymentMethodTitle: paymentMethodTitle,
        lineItems: lineItems,
        customAmounts: customAmounts,
        refunds: refunds,
        formattedDiscountTotal: nil,
        formattedTotalTax: "$0.00",
        formattedPaymentTotal: "$25.99",
        formattedNetAmount: nil,
        datePaid: status == .completed || status == .processing ? Date() : nil
    )
}

func makePOSOrderCustomAmount(
    id: Int64 = 1,
    name: String = "Discount Fee",
    formattedTotal: String = "$5.00",
    total: Decimal = 5,
    totalTax: Decimal = 0
) -> POSOrderCustomAmount {
    POSOrderCustomAmount(
        id: id,
        name: name,
        formattedTotal: formattedTotal,
        total: total,
        totalTax: totalTax
    )
}

func makePOSOrderItem(
    itemID: Int64 = 1,
    name: String = "Test Item",
    quantity: Decimal = 1,
    price: Decimal = 10.00,
    total: Decimal? = nil,
    totalTax: Decimal = 0,
    formattedPrice: String = "$10.00",
    formattedTotal: String? = nil,
    imageSrc: String? = nil,
    attributes: [OrderItemAttribute] = []
) -> POSOrderItem {
    POSOrderItem(
        itemID: itemID,
        name: name,
        quantity: quantity,
        price: price,
        total: total ?? (price * quantity),
        totalTax: totalTax,
        formattedPrice: formattedPrice,
        formattedTotal: formattedTotal ?? formattedPrice,
        imageSrc: imageSrc,
        attributes: attributes
    )
}
