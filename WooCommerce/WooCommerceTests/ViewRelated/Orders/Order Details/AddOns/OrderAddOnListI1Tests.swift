import XCTest
import Fakes

@testable import WooCommerce
@testable import Yosemite

class OrderAddOnListI1Tests: XCTestCase {

    func tests_addOns_view_models_are_correctly_converted_from_attributes() {
        // Given
        let attributes = [
            OrderItemAttribute(metaID: 1, name: "Topping ($3.00)", value: "Salami"),
            OrderItemAttribute(metaID: 2, name: "Fast Delivery ($7.00)", value: "Yes"),
            OrderItemAttribute(metaID: 3, name: "Soda (No Sugar) ($7.00)", value: "5"),
            OrderItemAttribute(metaID: 4, name: "Engraving", value: "Earned Not Given"),
        ]

        // When
        let viewModel = OrderAddOnListI1ViewModel(attributes: attributes)

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
        let attributes = [
            OrderItemAttribute(metaID: 1, name: "Topping ($3.00)", value: "Salami"),
            OrderItemAttribute(metaID: 2, name: "Fast Delivery ($7.00)", value: "Yes"),
            OrderItemAttribute(metaID: 3, name: "Soda (No Sugar) ($7.00)", value: "5"),
            OrderItemAttribute(metaID: 4, name: "Engraving", value: "Earned Not Given"),
        ]
        let viewModel = OrderAddOnListI1ViewModel(attributes: attributes, analytics: WooAnalytics(analyticsProvider: analytics))

        // When
        viewModel.trackAddOns()

        // Then
        XCTAssertEqual(analytics.receivedEvents, [WooAnalyticsStat.orderDetailAddOnsViewed.rawValue])

        let properties = try XCTUnwrap(analytics.receivedProperties.first?["add_ons"] as? String)
        XCTAssertEqual(properties, "Topping,Fast Delivery,Soda (No Sugar),Engraving")
    }
}
