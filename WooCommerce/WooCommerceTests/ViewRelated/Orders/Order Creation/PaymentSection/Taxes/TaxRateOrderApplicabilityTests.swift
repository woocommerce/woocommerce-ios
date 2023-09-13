import XCTest
@testable import WooCommerce
import Yosemite

final class TaxRateOrderApplicabilityTests: XCTestCase {
    func test_orderDetailsApplicabilityText_when_order_does_not_have_items_then_returns_nil() {
        let taxRate = TaxRate.fake()
        let order = Order.fake().copy(items: [])

        XCTAssertNil(taxRate.orderDetailsApplicabilityText(to: order))
    }

    func test_orderDetailsApplicabilityText_when_tax_rate_applies_to_order_then_returns_right_text() {
        let taxRateID: Int64 = 1
        let taxRate = TaxRate.fake().copy(id: 1)
        let order = Order.fake().copy(items: [OrderItem.fake()], taxes: [OrderTaxLine.fake().copy(rateID: taxRateID)])

        let text = taxRate.orderDetailsApplicabilityText(to: order)

        XCTAssertEqual(text, NSLocalizedString("Tax rate added automatically", comment: ""))
    }

    func test_orderDetailsApplicabilityText_when_order_has_products_but_not_taxes_then_returns_right_text() {
        let taxRate = TaxRate.fake().copy(id: 1)
        let order = Order.fake().copy(items: [OrderItem.fake()], taxes: [])

        let text = taxRate.orderDetailsApplicabilityText(to: order)

        XCTAssertEqual(text, NSLocalizedString("This rate doesn't apply to these products", comment: ""))
    }

    func test_orderDetailsApplicabilityText_when_order_has_products_and_taxes_without_the_right_class_then_returns_right_text() {
        let taxRate = TaxRate.fake().copy(id: 1, taxRateClass: "tax class 1")
        let order = Order.fake().copy(items: [OrderItem.fake().copy(taxClass: "tax class 2")], taxes: [OrderTaxLine.fake().copy(rateID: 2)])

        let text = taxRate.orderDetailsApplicabilityText(to: order)

        XCTAssertEqual(text, NSLocalizedString("This rate doesn't apply to these products", comment: ""))
    }

    func test_orderDetailsApplicabilityText_when_order_has_products_with_the_right_class_and__different_taxes_then_returns_right_text() {
        let taxRateClass = "tax class"
        let taxRate = TaxRate.fake().copy(id: 1, taxRateClass: taxRateClass)
        let order = Order.fake().copy(items: [OrderItem.fake().copy(taxClass: taxRateClass)], taxes: [OrderTaxLine.fake().copy(rateID: 2)])

        let text = taxRate.orderDetailsApplicabilityText(to: order)

        XCTAssertEqual(text, NSLocalizedString("This rate does not apply because another rate has higher priority", comment: ""))
    }
}
