import XCTest
@testable import Yosemite

final class Product_OrderItemTests: XCTestCase {

    func test_product_to_order_item() {
        // Given
        let productID: Int64 = 5
        let name = "Test Product"
        let quantity: Decimal = 2
        let price: Decimal = 2.50
        let total = (quantity * price).description
        let product = Product.fake().copy(productID: productID, name: name, price: price.description)
        let expectedOrderItem = OrderItem(itemID: 0,
                                          name: name,
                                          productID: productID,
                                          variationID: 0,
                                          quantity: quantity,
                                          price: NSDecimalNumber(decimal: price),
                                          sku: nil,
                                          subtotal: total,
                                          subtotalTax: "",
                                          taxClass: "",
                                          taxes: [],
                                          total: total,
                                          totalTax: "0",
                                          attributes: [])

        // Then
        XCTAssertEqual(product.toOrderItem(quantity: quantity), expectedOrderItem)
    }
}
