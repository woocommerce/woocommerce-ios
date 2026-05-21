@testable import PointOfSale
import XCTest
@testable import WooCommerce
import WooFoundation
import Yosemite

final class POSRefundSubmissionMappingTests: XCTestCase {
    private var sut: POSRefundSubmissionMapping!

    override func setUp() {
        super.setUp()
        let currencySettings = CurrencySettings(currencyCode: .USD,
                                                currencyPosition: .left,
                                                thousandSeparator: ",",
                                                decimalSeparator: ".",
                                                numberOfDecimals: 2)
        sut = POSRefundSubmissionMapping(currencyFormatter: CurrencyFormatter(currencySettings: currencySettings))
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func test_normalizedForPOSInteracRefund_converts_cardPresent_interac_to_interacPresent() {
        let details = WCPayCardPresentPaymentDetails.fake().copy(brand: .interac, last4: "4242")
        let charge = WCPayCharge.fake().copy(paymentMethodDetails: .cardPresent(details: details))

        let normalizedCharge = sut.normalizedForPOSInteracRefund(charge: charge)

        guard case .interacPresent(let normalizedDetails) = normalizedCharge.paymentMethodDetails else {
            return XCTFail("Expected Interac card-present charge to be normalized to interac_present.")
        }
        XCTAssertEqual(normalizedDetails, details)
    }

    func test_normalizedForPOSInteracRefund_keeps_non_interac_cardPresent_charge_unchanged() {
        let details = WCPayCardPresentPaymentDetails.fake().copy(brand: .visa, last4: "4242")
        let charge = WCPayCharge.fake().copy(paymentMethodDetails: .cardPresent(details: details))

        let normalizedCharge = sut.normalizedForPOSInteracRefund(charge: charge)

        XCTAssertEqual(normalizedCharge, charge)
    }

    func test_gatewaySupportsAutomaticRefunds_uses_gateway_refunds_feature_when_gateway_is_available() {
        let refundingGateway = PaymentGateway.fake().copy(features: [.refunds])
        let nonRefundingGateway = PaymentGateway.fake().copy(features: [.products])

        XCTAssertTrue(sut.gatewaySupportsAutomaticRefunds(context: makeContext(paymentGateway: refundingGateway)))
        XCTAssertFalse(sut.gatewaySupportsAutomaticRefunds(context: makeContext(paymentGateway: nonRefundingGateway)))
    }

    func test_gatewaySupportsAutomaticRefunds_falls_back_to_order_payment_method_without_gateway() {
        let cardOrder = Order.fake().copy(paymentMethodID: WCPayAccount.gatewayID)
        let codOrder = Order.fake().copy(paymentMethodID: PaymentGateway.Constants.cashOnDeliveryGatewayID)

        XCTAssertTrue(sut.gatewaySupportsAutomaticRefunds(context: makeContext(order: cardOrder, paymentGateway: nil)))
        XCTAssertFalse(sut.gatewaySupportsAutomaticRefunds(context: makeContext(order: codOrder, paymentGateway: nil)))
    }

    func test_refundComponents_aggregates_selected_product_quantity_and_selected_fees() {
        let item1 = orderItem(itemID: 10, quantity: 3)
        let item2 = orderItem(itemID: 20, quantity: 1)
        let fee1 = orderFee(feeID: 100)
        let fee2 = orderFee(feeID: 200)
        let context = makeContext(refundableItems: [
            RefundableOrderItem(item: item1, quantity: 3),
            RefundableOrderItem(item: item2, quantity: 1)
        ], refundableFees: [fee1, fee2])
        let selectedItems = [
            selectableItem(itemID: item1.itemID, index: 0),
            selectableItem(itemID: item1.itemID, index: 1),
            selectableItem(itemID: fee2.feeID, isLumpSum: true, index: 2)
        ]

        let components = sut.refundComponents(from: selectedItems, context: context)

        XCTAssertEqual(components.items, [RefundableOrderItem(item: item1, quantity: 2)])
        XCTAssertEqual(components.fees, [fee2])
    }

    func test_determineRefundableFees_excludes_fees_refunded_by_original_or_refund_fee_id() {
        let fee1 = orderFee(feeID: 100)
        let fee2 = orderFee(feeID: 200)
        let fee3 = orderFee(feeID: 300)
        let order = Order.fake().copy(fees: [fee1, fee2, fee3])
        let refundUsingOriginalFeeID = Refund.fake().copy(feeLines: [
            orderFee(feeID: 900, refundedItemID: fee1.feeID)
        ])
        let refundUsingRefundFeeID = Refund.fake().copy(feeLines: [
            orderFee(feeID: fee2.feeID, refundedItemID: nil)
        ])

        let refundableFees = sut.determineRefundableFees(from: order,
                                                         with: [refundUsingOriginalFeeID, refundUsingRefundFeeID])

        XCTAssertEqual(refundableFees, [fee3])
    }

    func test_makeSelectableItems_expands_refundable_product_quantities_and_appends_fees() {
        let item = orderItem(itemID: 10,
                             name: "Coffee",
                             quantity: 2,
                             price: 4,
                             total: "8.00",
                             totalTax: "0.80")
        let fee = orderFee(feeID: 200, name: "   ", total: "3.50", totalTax: "0.35")

        let selectableItems = sut.makeSelectableItems(refundableItems: [RefundableOrderItem(item: item, quantity: 2)],
                                                      fees: [fee],
                                                      currency: "USD")

        XCTAssertEqual(selectableItems.count, 3)
        XCTAssertEqual(selectableItems.map(\.itemID), [item.itemID, item.itemID, fee.feeID])
        XCTAssertEqual(selectableItems.map(\.isLumpSum), [false, false, true])
        XCTAssertEqual(selectableItems.map(\.isSelected), [true, true, true])
        XCTAssertEqual(selectableItems[0].lineItemTotal, Decimal(8))
        XCTAssertEqual(selectableItems[0].totalTax, NSDecimalNumber(string: "0.80").decimalValue)
        XCTAssertEqual(selectableItems[2].name, "Custom amount")
        XCTAssertEqual(selectableItems[2].lineItemTotal, NSDecimalNumber(string: "3.50").decimalValue)
        XCTAssertEqual(selectableItems[2].totalTax, NSDecimalNumber(string: "0.35").decimalValue)
    }
}

private extension POSRefundSubmissionMappingTests {
    func makeContext(order: Order = Order.fake(),
                     paymentGateway: PaymentGateway? = PaymentGateway.fake(),
                     refundableItems: [RefundableOrderItem] = [],
                     refundableFees: [OrderFeeLine] = []) -> POSRefundSubmissionMapping.PreparedRefundContext {
        POSRefundSubmissionMapping.PreparedRefundContext(order: order,
                                                         charge: nil,
                                                         paymentGateway: paymentGateway,
                                                         paymentGatewayAccount: nil,
                                                         refundableItems: refundableItems,
                                                         refundableFees: refundableFees)
    }

    func orderItem(itemID: Int64,
                   name: String = "Product",
                   quantity: Decimal,
                   price: Decimal = 5,
                   total: String = "5.00",
                   totalTax: String = "0.50") -> OrderItem {
        OrderItem.fake().copy(itemID: itemID,
                              name: name,
                              quantity: quantity,
                              price: NSDecimalNumber(decimal: price),
                              total: total,
                              totalTax: totalTax,
                              attributes: [])
    }

    func orderFee(feeID: Int64,
                  name: String? = "Fee",
                  total: String = "1.00",
                  totalTax: String = "0.10",
                  refundedItemID: Int64? = nil) -> OrderFeeLine {
        OrderFeeLine.fake().copy(feeID: feeID,
                                 name: name,
                                 total: total,
                                 totalTax: totalTax,
                                 attributes: [],
                                 refundedItemID: refundedItemID)
    }

    func selectableItem(itemID: Int64, isLumpSum: Bool = false, index: Int) -> POSRefundSelectableItem {
        POSRefundSelectableItem(itemID: itemID,
                                name: "Selected",
                                imageSrc: nil,
                                lineItemTotal: 1,
                                totalTax: 0,
                                originalQuantity: 1,
                                formattedPrice: "$1.00",
                                attributes: [],
                                isLumpSum: isLumpSum,
                                isSelected: true,
                                index: index)
    }
}
