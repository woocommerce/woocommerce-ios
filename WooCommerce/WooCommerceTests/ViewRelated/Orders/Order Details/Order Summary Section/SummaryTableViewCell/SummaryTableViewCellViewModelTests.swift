
import Foundation
import XCTest

import Yosemite

@testable import WooCommerce

/// Tests for `SummaryTableViewCellViewModel`.
///
final class SummaryTableViewCellViewModelTests: XCTestCase {

    func test_billedPersonName_returns_the_name_from_the_billing_address() {
        // Given
        let address = Address(firstName: "Skylar",
                              lastName: "Ferry",
                              company: nil,
                              address1: "",
                              address2: nil,
                              city: "",
                              state: "",
                              postcode: "",
                              country: "",
                              phone: nil,
                              email: nil)
        let order = makeOrder(billingAddress: address)

        // When
        let personName = SummaryTableViewCellViewModel(order: order, status: nil).billedPersonName

        // Then
        XCTAssertEqual(personName, "Skylar Ferry")
    }

    func test_subtitle_returns_the_date_and_time_and_order_number() throws {
        // Given
        let expectedFormatter = DateFormatter.dateAndTimeFormatter
        let calendar = Calendar(identifier: .gregorian, timeZone: expectedFormatter.timeZone)

        let order = makeOrder(dateCreated: Date())

        let viewModel = SummaryTableViewCellViewModel(order: order,
                                                      status: nil,
                                                      calendar: calendar)

        // When
        let subtitle = viewModel.subtitle

        // Then
        let expectedSubtitle = expectedFormatter.string(from: order.dateCreated) + " • #\(order.number)"
        XCTAssertEqual(subtitle, expectedSubtitle)
    }
}

private extension SummaryTableViewCellViewModelTests {
    func makeOrder(dateCreated: Date = Date(), billingAddress: Address? = nil) -> Order {
        return Order.fake().copy(siteID: 123,
                                 orderID: 963,
                                 parentID: 2,
                                 customerID: 11,
                                 orderKey: "abc123",
                                 number: "963",
                                 status: .custom("automattic"),
                                 currency: "USD",
                                 customerNote: "",
                                 dateCreated: dateCreated,
                                 datePaid: Date(),
                                 discountTotal: "30.00",
                                 discountTax: "1.20",
                                 shippingTotal: "0.00",
                                 shippingTax: "0.00",
                                 total: "31.20",
                                 totalTax: "1.20",
                                 paymentMethodID: "stripe",
                                 paymentMethodTitle: "Credit Card (Stripe)",
                                 items: [],
                                 billingAddress: billingAddress)
    }
}
