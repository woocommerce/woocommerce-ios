import XCTest
import Fakes

@testable import WooCommerce
@testable import Yosemite

final class OrderAddOnListI1Tests: XCTestCase {

    func tests_addOns_view_models_are_correctly_converted_from_attributes() {
        // Given
        let addOns = [
            OrderItemProductAddOn(addOnID: 1, key: "Topping ($3.00)", value: "Salami"),
            OrderItemProductAddOn(addOnID: 2, key: "Fast Delivery ($7.00)", value: "Yes"),
            OrderItemProductAddOn(addOnID: 3, key: "Soda (No Sugar) ($7.00)", value: "5"),
            OrderItemProductAddOn(addOnID: 4, key: "Engraving", value: "Earned Not Given"),
        ]

        // When
        let viewModel = OrderAddOnListI1ViewModel(addOns: addOns)

        // Then
        XCTAssertEqual(viewModel.addOns, [
            OrderAddOnI1ViewModel.init(id: 1, title: "Topping", content: "Salami", price: "$3.00"),
            OrderAddOnI1ViewModel.init(id: 2, title: "Fast Delivery", content: "Yes", price: "$7.00"),
            OrderAddOnI1ViewModel.init(id: 3, title: "Soda (No Sugar)", content: "5", price: "$7.00"),
            OrderAddOnI1ViewModel.init(id: 4, title: "Engraving", content: "Earned Not Given", price: "")
        ])
    }

    func test_addOns_are_properly_tracked() throws {
        // Given
        let analytics = MockAnalyticsProvider()
        let addOns = [
            OrderItemProductAddOn(addOnID: 1, key: "Topping ($3.00)", value: "Salami"),
            OrderItemProductAddOn(addOnID: 2, key: "Fast Delivery ($7.00)", value: "Yes"),
            OrderItemProductAddOn(addOnID: 3, key: "Soda (No Sugar) ($7.00)", value: "5"),
            OrderItemProductAddOn(addOnID: 4, key: "Engraving", value: "Earned Not Given"),
        ]
        let viewModel = OrderAddOnListI1ViewModel(addOns: addOns, analytics: WooAnalytics(analyticsProvider: analytics))

        // When
        viewModel.trackAddOns()

        // Then
        XCTAssertEqual(analytics.receivedEvents, [WooAnalyticsStat.orderDetailAddOnsViewed.rawValue])

        let properties = try XCTUnwrap(analytics.receivedProperties.first?["add_ons"] as? String)
        XCTAssertEqual(properties, "Topping,Fast Delivery,Soda (No Sugar),Engraving")
    }
}
