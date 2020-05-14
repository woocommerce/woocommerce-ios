
import Foundation
import XCTest

import Yosemite

@testable import WooCommerce

/// Tests for `SummaryTableViewCellViewModel`.
///
final class SummaryTableViewCellViewModelTests: XCTestCase {

    func testBilledPersonNameReturnsTheNameFromTheBillingAddress() {
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

    func testSubtitleReturnsTheDateAndOrderNumber() throws {
        // Given
        let expectedFormatter = DateFormatter.mediumLengthLocalizedDateFormatter
        let calendar = Calendar(identifier: .gregorian, timeZone: expectedFormatter.timeZone)

        let order = makeOrder(dateCreated: try XCTUnwrap(Date().adding(days: -2, using: calendar)))

        let viewModel = SummaryTableViewCellViewModel(order: order,
                                                      status: nil,
                                                      calendar: calendar,
                                                      layoutDirection: .leftToRight)

        // When
        let subtitle = viewModel.dateCreatedAndOrderNumber

        // Then
        let expectedSubtitle = expectedFormatter.string(from: order.dateCreated) + " • #\(order.number)"
        XCTAssertEqual(subtitle, expectedSubtitle)
    }

    func testGivenRTLThenSubtitleReturnsTheDateAndOrderNumberInReverse() throws {
        // Given
        let expectedFormatter = DateFormatter.mediumLengthLocalizedDateFormatter
        let calendar = Calendar(identifier: .gregorian, timeZone: expectedFormatter.timeZone)

        let order = makeOrder(dateCreated: try XCTUnwrap(Date().adding(days: -2, using: calendar)))

        let viewModel = SummaryTableViewCellViewModel(order: order,
                                                      status: nil,
                                                      calendar: calendar,
                                                      layoutDirection: .rightToLeft)

        // When
        let subtitle = viewModel.dateCreatedAndOrderNumber

        // Then
        let expectedSubtitle = "#\(order.number) • " + expectedFormatter.string(from: order.dateCreated)
        XCTAssertEqual(subtitle, expectedSubtitle)
    }

    func testGivenAnOrderCreatedTodayThenSubtitleReturnsTheTimeAndOrderNumber() {
        // Given
        let expectedFormatter = DateFormatter.timeFormatter
        let calendar = Calendar(identifier: .gregorian, timeZone: expectedFormatter.timeZone)

        let order = makeOrder(dateCreated: Date())

        let viewModel = SummaryTableViewCellViewModel(order: order,
                                                      status: nil,
                                                      calendar: calendar,
                                                      layoutDirection: .leftToRight)

        // When
        let subtitle = viewModel.dateCreatedAndOrderNumber

        // Then
        let expectedSubtitle = expectedFormatter.string(from: order.dateCreated) + " • #\(order.number)"
        XCTAssertEqual(subtitle, expectedSubtitle)
    }
}

private extension SummaryTableViewCellViewModelTests {
    func makeOrder(dateCreated: Date = Date(), billingAddress: Address? = nil) -> Order {
        return Order(siteID: 123,
                     orderID: 963,
                     parentID: 2,
                     customerID: 11,
                     number: "963",
                     statusKey: "automattic",
                     currency: "USD",
                     customerNote: "",
                     dateCreated: dateCreated,
                     dateModified: Date(),
                     datePaid: Date(),
                     discountTotal: "30.00",
                     discountTax: "1.20",
                     shippingTotal: "0.00",
                     shippingTax: "0.00",
                     total: "31.20",
                     totalTax: "1.20",
                     paymentMethodTitle: "Credit Card (Stripe)",
                     items: [],
                     billingAddress: billingAddress,
                     shippingAddress: nil,
                     shippingLines: [],
                     coupons: [],
                     refunds: [])
    }
}
