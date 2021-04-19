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
        ]

        // When
        let viewModel = OrderAddOnListI1ViewModel(attributes: attributes)

        // Then
        XCTAssertEqual(viewModel.addOns, [
            OrderAddOnI1ViewModel.init(id: 1, title: "Topping", content: "Salami", price: "$3.00"),
            OrderAddOnI1ViewModel.init(id: 2, title: "Fast Delivery", content: "Yes", price: "$7.00"),
            OrderAddOnI1ViewModel.init(id: 3, title: "Soda (No Sugar)", content: "5", price: "$7.00")
        ])
    }
}
