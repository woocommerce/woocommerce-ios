import XCTest
import Fakes

@testable import WooCommerce
@testable import Yosemite
@testable import Networking

class AddOnCrossreferenceTests: XCTestCase {

    func tests_addOn_attributes_are_correctly_filtered_against_product_addOns() {
        // Given
        let orderItem = MockAggregateOrderItem.emptyItem().copy(attributes: [
            OrderItemAttribute(metaID: 1, name: "Topping ($3.00)", value: ""),
            OrderItemAttribute(metaID: 2, name: "Random Attribute 1", value: ""),
            OrderItemAttribute(metaID: 3, name: "Fast Delivery ($7.00)", value: ""),
            OrderItemAttribute(metaID: 4, name: "NotOnProduct ($7.00)", value: ""),
        ])
        let product = Product.fake().copy(addOns: [
            ProductAddOn.fake().copy(name: "Fast Delivery"),
            ProductAddOn.fake().copy(name: "Topping"),
            ProductAddOn.fake().copy(name: "Schedule"),
        ])

        // When
        let useCase = AddOnCrossreferenceUseCase(orderItem: orderItem, product: product)
        let addOnsAttributes = useCase.addOnsAttributes()

        // Then
        XCTAssertEqual(addOnsAttributes, [
            OrderItemAttribute(metaID: 1, name: "Topping ($3.00)", value: ""),
            OrderItemAttribute(metaID: 3, name: "Fast Delivery ($7.00)", value: ""),
        ])
    }

    func tests_addOn_attributes_with_special_characters_in_name_are_correctly_filtered_against_product_addOns() {
        // Given
        let orderItem = MockAggregateOrderItem.emptyItem().copy(attributes: [
            OrderItemAttribute(metaID: 3, name: "Fast (really) Delivery (fast) ($7.00)", value: ""),
        ])
        let product = Product.fake().copy(addOns: [
            ProductAddOn.fake().copy(name: "Fast (really) Delivery (fast)"),
        ])

        // When
        let useCase = AddOnCrossreferenceUseCase(orderItem: orderItem, product: product)
        let addOnsAttributes = useCase.addOnsAttributes()

        // Then
        XCTAssertEqual(addOnsAttributes, [
            OrderItemAttribute(metaID: 3, name: "Fast (really) Delivery (fast) ($7.00)", value: ""),
        ])
    }

    func tests_addOnAttributes_is_empty_when_product_does_not_have_addOns() {
        // Given
        let orderItem = MockAggregateOrderItem.emptyItem().copy(attributes: [
            OrderItemAttribute(metaID: 1, name: "Topping ($3.00)", value: ""),
            OrderItemAttribute(metaID: 2, name: "Random Attribute 1", value: ""),
            OrderItemAttribute(metaID: 3, name: "Fast Delivery (%7.00)", value: ""),
            OrderItemAttribute(metaID: 4, name: "NotOnProduct (%7.00)", value: ""),
        ])
        let product = Product.fake()

        // When
        let useCase = AddOnCrossreferenceUseCase(orderItem: orderItem, product: product)
        let addOnsAttributes = useCase.addOnsAttributes()

        // Then
        XCTAssertTrue(addOnsAttributes.isEmpty)
    }

    func tests_addOnAttributes_is_empty_when_orderItem_does_not_have_attributes() {
        // Given
        let orderItem = MockAggregateOrderItem.emptyItem()
        let product = Product.fake().copy(addOns: [
            ProductAddOn.fake().copy(name: "Fast Delivery"),
            ProductAddOn.fake().copy(name: "Topping"),
            ProductAddOn.fake().copy(name: "Schedule"),
        ])

        // When
        let useCase = AddOnCrossreferenceUseCase(orderItem: orderItem, product: product)
        let addOnsAttributes = useCase.addOnsAttributes()

        // Then
        XCTAssertTrue(addOnsAttributes.isEmpty)
    }
}
