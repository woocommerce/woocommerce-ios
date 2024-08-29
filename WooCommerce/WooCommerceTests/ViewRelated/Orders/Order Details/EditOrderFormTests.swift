import Foundation
import XCTest
import TestKit
import Yosemite
import ViewInspector

@testable import WooCommerce

final class EditOrderFormTests: XCTestCase {

    func test_addition_buttons_on_empty_orders() throws {
        // Given
        let order = MockOrders().empty()

        // When
        let sut = try Self.createEditView(with: order).inspect()

        // Then
        XCTAssertNotNil(try? sut.find(button: "Add Products"))
        XCTAssertNotNil(try? sut.find(button: "Add Custom Amount"))
        XCTAssertNotNil(try? sut.find(button: "Add Customer"))
        XCTAssertNotNil(try? sut.find(button: "Add Note"))
        XCTAssertNotNil(try? sut.find(button: "Done"))
    }

    func test_components_on_editable_order_with_items() throws {
        // Given
        let order = MockOrders().empty().copy(isEditable: true, status: .onHold, items: MockOrders().sampleOrderItems())

        // When
        let sut = try Self.createEditView(with: order).inspect()

        // Then
        XCTAssertNotNil(try? sut.find(text: "Products"))
        XCTAssertNotNil(try? sut.find(text: "Order total"))

        XCTAssertNotNil(try? sut.find(viewWithAccessibilityLabel: "Add product"))
        XCTAssertNotNil(try? sut.find(button: "Add Custom Amount"))
        XCTAssertNotNil(try? sut.find(button: "Add Shipping"))
        XCTAssertNotNil(try? sut.find(button: "Add Coupon"))
        XCTAssertNotNil(try? sut.find(button: "Add Customer"))
        XCTAssertNotNil(try? sut.find(button: "Add Note"))
        XCTAssertNotNil(try? sut.find(button: "Done"))
    }

    func test_components_on_editable_order_with_custom_amount() throws {
        // Given
        let order = MockOrders().empty().copy(isEditable: true, status: .onHold, fees: MockOrders().sampleFeeLines())

        // When
        let sut = try Self.createEditView(with: order).inspect()

        // Then
        XCTAssertNotNil(try? sut.find(text: "Custom Amounts"))
        XCTAssertNotNil(try? sut.find(text: "Order total"))

        XCTAssertNotNil(try? sut.find(viewWithAccessibilityLabel: "Edit amount"))
        XCTAssertNotNil(try? sut.find(button: "Add Shipping"))
        XCTAssertNotNil(try? sut.find(button: "Add Customer"))
        XCTAssertNotNil(try? sut.find(button: "Add Note"))
        XCTAssertNotNil(try? sut.find(button: "Done"))
    }

    func test_components_on_editable_order_with_shipping_and_customer_information() throws {
        // Given
        let order = MockOrders().sampleOrder().copy(isEditable: true, status: .onHold)

        // When
        let sut = try Self.createEditView(with: order).inspect()

        // Then
        XCTAssertNotNil(try? sut.find(text: "Shipping"))
        XCTAssertNotNil(try? sut.find(text: "Customer"))
        XCTAssertNotNil(try? sut.find(text: "Order total"))

        XCTAssertNotNil(try? sut.find(viewWithAccessibilityLabel: "Edit shipping"))
        XCTAssertNotNil(try? sut.find(viewWithAccessibilityLabel: "Search customer"))

        XCTAssertNotNil(try? sut.find(button: "Add Products"))
        XCTAssertNotNil(try? sut.find(button: "Add Custom Amount"))
        XCTAssertNotNil(try? sut.find(button: "Add Note"))
        XCTAssertNotNil(try? sut.find(button: "Done"))
    }

    func test_components_on_editable_order_with_order_note() throws {
        // Given
        let order = MockOrders().empty().copy(isEditable: true, status: .onHold, customerNote: "Some Note")

        // When
        let sut = try Self.createEditView(with: order).inspect()

        // Then
        XCTAssertNotNil(try? sut.find(text: "Customer Note"))
        XCTAssertNotNil(try? sut.find(text: "Order total"))

        XCTAssertNotNil(try? sut.find(viewWithAccessibilityLabel: "Edit customer note"))

        XCTAssertNotNil(try? sut.find(button: "Add Products"))
        XCTAssertNotNil(try? sut.find(button: "Add Custom Amount"))
        XCTAssertNotNil(try? sut.find(button: "Add Customer"))
        XCTAssertNotNil(try? sut.find(button: "Done"))
    }
}

// MARK: Helpers
private extension EditOrderFormTests {
    static func createEditView(with order: Order) -> OrderForm {
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let storage = MockStorageManager()

        // Insert products that relates to items into the storage.
        // This is needed by EditableOrderViewModel to properly compute its variables
        for item in order.items {
            let product = Product.fake().copy(siteID: order.siteID, productID: item.productID)
            storage.insertSampleProduct(readOnlyProduct: product)
        }

        let viewModel = EditableOrderViewModel(siteID: order.siteID,
                                               flow: .editing(initialOrder: order),
                                               stores: stores,
                                               storageManager: storage)
        return OrderForm(flow: .editing, viewModel: viewModel, presentProductSelector: {})
    }

}
