import XCTest
@testable import WooCommerce
import Yosemite

final class ProductLoaderViewControllerModelTests: XCTestCase {
    // MARK: - Init with `OrderItem`

    func test_init_with_OrderItem_without_a_variationID_sets_model_as_product() {
        // Arrange
        let orderItem = makeOrderItem(productID: 2, variationID: 0)

        // Action
        let productLoaderModel = ProductLoaderViewController.Model(orderItem: orderItem)

        // Assert
        XCTAssertEqual(productLoaderModel, .product(productID: 2))
    }

    func test_init_with_OrderItem_with_a_variationID_sets_model_as_variation() {
        // Arrange
        let orderItem = makeOrderItem(productID: 2, variationID: 99)

        // Action
        let productLoaderModel = ProductLoaderViewController.Model(orderItem: orderItem)

        // Assert
        XCTAssertEqual(productLoaderModel, .productVariation(productID: 2, variationID: 99))
    }

    // MARK: - Init with `OrderItemRefund`

    func test_init_with_OrderItemRefund_without_a_variationID_sets_model_as_product() {
        // Arrange
        let orderItemRefund = makeOrderItemRefund(productID: 2, variationID: 0)

        // Action
        let productLoaderModel = ProductLoaderViewController.Model(orderItemRefund: orderItemRefund)

        // Assert
        XCTAssertEqual(productLoaderModel, .product(productID: 2))
    }

    func test_init_with_OrderItemRefund_with_a_variationID_sets_model_as_variation() {
        // Arrange
        let orderItemRefund = makeOrderItemRefund(productID: 2, variationID: 99)

        // Action
        let productLoaderModel = ProductLoaderViewController.Model(orderItemRefund: orderItemRefund)

        // Assert
        XCTAssertEqual(productLoaderModel, .productVariation(productID: 2, variationID: 99))
    }

    // MARK: - Init with `AggregateOrderItem`

    func test_init_with_AggregateOrderItem_without_a_variationID_sets_model_as_product() {
        // Arrange
        let item = makeAggregateOrderItem(productID: 2, variationID: 0)

        // Action
        let productLoaderModel = ProductLoaderViewController.Model(aggregateOrderItem: item)

        // Assert
        XCTAssertEqual(productLoaderModel, .product(productID: 2))
    }

    func test_init_with_AggregateOrderItem_with_a_variationID_sets_model_as_variation() {
        // Arrange
        let item = makeAggregateOrderItem(productID: 2, variationID: 99)

        // Action
        let productLoaderModel = ProductLoaderViewController.Model(aggregateOrderItem: item)

        // Assert
        XCTAssertEqual(productLoaderModel, .productVariation(productID: 2, variationID: 99))
    }

    // MARK: - Init with `TopEarnerStatsItem`

    func test_init_with_TopEarnerStatsItem_sets_model_as_product() {
        // Arrange
        let item = makeTopEarnerStatsItem(productID: 0)

        // Action
        let productLoaderModel = ProductLoaderViewController.Model(topEarnerStatsItem: item)

        // Assert
        XCTAssertEqual(productLoaderModel, .product(productID: 0))
    }
}

private extension ProductLoaderViewControllerModelTests {
    func makeOrderItem(productID: Int64, variationID: Int64) -> OrderItem {
        OrderItem(itemID: 0,
                  name: "fun order",
                  productID: productID,
                  variationID: variationID,
                  quantity: 2,
                  price: 2.5,
                  sku: nil,
                  subtotal: "0",
                  subtotalTax: "1.0",
                  taxClass: "",
                  taxes: [],
                  total: "",
                  totalTax: "",
                  attributes: [])
    }

    func makeOrderItemRefund(productID: Int64, variationID: Int64) -> OrderItemRefund {
        OrderItemRefund(itemID: 73,
                        name: "Ninja Silhouette",
                        productID: productID,
                        variationID: variationID,
                        quantity: -1,
                        price: 18,
                        sku: "T-SHIRT-NINJA-SILHOUETTE",
                        subtotal: "-18.00",
                        subtotalTax: "0.00",
                        taxClass: "",
                        taxes: [],
                        total: "-18.00",
                        totalTax: "0.00")
    }

    func makeAggregateOrderItem(productID: Int64, variationID: Int64) -> AggregateOrderItem {
        AggregateOrderItem(productID: productID,
                           variationID: variationID,
                           name: "order",
                           price: 1.2,
                           quantity: 3,
                           sku: nil,
                           total: 3.6,
                           attributes: [])
    }

    func makeTopEarnerStatsItem(productID: Int64) -> TopEarnerStatsItem {
        TopEarnerStatsItem(productID: productID,
                           productName: "Album",
                           quantity: 1,
                           price: 15.0,
                           total: 15.99,
                           currency: "",
                           imageUrl: "https://dulces.mystagingwebsite.com/wp-content/uploads/2020/06/album-1.jpg")
    }
}
