import XCTest
@testable import WooCommerce
import Yosemite

final class AggregatedShippingLabelOrderItemsTests: XCTestCase {
    func test_order_items_from_shipping_label_without_Product_and_ProductVariation_only_have_name() {
        // Given
        let shippingLabel = MockShippingLabel.emptyLabel().copy(productIDs: [3013], productNames: ["Password protected!"])
        let orderItem = MockOrderItem.sampleItem(productID: 3013)
        let aggregatedOrderItems = AggregatedShippingLabelOrderItems(shippingLabels: [shippingLabel],
                                                                     orderItems: [orderItem],
                                                                     products: [],
                                                                     productVariations: [])

        // When
        let shippingLabelOrderItems = aggregatedOrderItems.orderItems(of: shippingLabel)

        // Then
        XCTAssertEqual(shippingLabelOrderItems, [
            .init(itemID: "0",
                  productID: 0,
                  variationID: 0,
                  name: "Password protected!",
                  price: nil,
                  quantity: 0,
                  sku: nil,
                  total: nil,
                  attributes: [],
                  addOns: [],
                  parent: nil)
        ])
        XCTAssertEqual(shippingLabelOrderItems[0], aggregatedOrderItems.orderItem(of: shippingLabel, at: 0))
    }

    func test_order_items_from_shipping_label_with_matching_Product_have_expected_properties() {
        // Given
        let shippingLabel = MockShippingLabel.emptyLabel().copy(productIDs: [2020, 3013, 3013, 3013],
                                                                productNames: ["Woo", "PW", "PW", "PW"])
        let imageURL1 = URL(string: "woocommerce.com/woocommerce.jpeg")!
        let product1 = Product.fake().copy(productID: 2020, name: "Whoa", price: "25.9", images: [createProductImage(src: imageURL1.absoluteString)])
        let product2 = Product.fake().copy(productID: 3013, name: "Password", price: "25.9")
        let orderItem1 = MockOrderItem.sampleItem(itemID: 1, name: "Woooo", productID: 2020, price: 59.2, sku: "woo")
        let aggregatedOrderItems = AggregatedShippingLabelOrderItems(shippingLabels: [shippingLabel],
                                                                     orderItems: [orderItem1],
                                                                     products: [product1, product2],
                                                                     productVariations: [])

        // When
        let shippingLabelOrderItems = aggregatedOrderItems.orderItems(of: shippingLabel)

        // Then
        XCTAssertEqual(shippingLabelOrderItems, [
            // Product with ID 2020 has a matching OrderItem and the name, price, SKU, and attributes are from `OrderItem`.
            .init(itemID: orderItem1.itemID.description,
                  productID: 2020,
                  variationID: 0,
                  name: orderItem1.name,
                  price: 59.2,
                  quantity: 1,
                  sku: orderItem1.sku,
                  total: 59.2,
                  imageURL: imageURL1,
                  attributes: orderItem1.attributes,
                  addOns: [],
                  parent: nil),
            // Product with ID 3013 does not have a matching OrderItem so the price and SKU come from the Product.
            // Since a Product's name could change, the name falls back to the name in shipping label's `productNames`.
                .init(itemID: "0",
                      productID: 3013,
                      variationID: 0,
                      name: "PW",
                      price: 25.9,
                      quantity: 3,
                      sku: product2.sku,
                      total: 77.7,
                      attributes: [],
                      addOns: [],
                      parent: nil)
        ])
        XCTAssertEqual(shippingLabelOrderItems[0], aggregatedOrderItems.orderItem(of: shippingLabel, at: 0))
        XCTAssertEqual(shippingLabelOrderItems[1], aggregatedOrderItems.orderItem(of: shippingLabel, at: 1))
    }

    func test_order_items_from_shipping_label_with_matching_ProductVariation_and_OrderItem_have_expected_properties() {
        // Given
        let shippingLabel = MockShippingLabel.emptyLabel().copy(productIDs: [3013], productNames: ["Password protected!"])
        let imageURL = URL(string: "woocommerce.com/woocommerce.jpeg")!
        let variation = MockProductVariation().productVariation()
            .copy(productID: 100,
                  productVariationID: 3013,
                  image: createProductImage(src: imageURL.absoluteString),
                  price: "62")
        let orderItem = MockOrderItem.sampleItem(itemID: 1,
                                                 productID: 100,
                                                 variationID: 3013,
                                                 quantity: 15,
                                                 price: 25.9,
                                                 sku: "woo",
                                                 attributes: [
                                                    .init(metaID: 205, name: "Platform", value: "Digital")
                                                 ])
        let aggregatedOrderItems = AggregatedShippingLabelOrderItems(shippingLabels: [shippingLabel],
                                                                     orderItems: [orderItem],
                                                                     products: [],
                                                                     productVariations: [variation])

        // When
        let shippingLabelOrderItems = aggregatedOrderItems.orderItems(of: shippingLabel)

        // Then
        XCTAssertEqual(shippingLabelOrderItems, [
            // The itemID, name, price, SKU, and attributes come from `OrderItem`.
            .init(itemID: orderItem.itemID.description,
                  productID: 100,
                  variationID: 3013,
                  name: orderItem.name,
                  price: 25.9,
                  quantity: 1,
                  sku: orderItem.sku,
                  total: 25.9,
                  imageURL: imageURL,
                  attributes: orderItem.attributes,
                  addOns: [],
                  parent: nil)
        ])
        XCTAssertEqual(shippingLabelOrderItems[0], aggregatedOrderItems.orderItem(of: shippingLabel, at: 0))
    }

    func test_order_items_from_shipping_label_with_matching_ProductVariation_and_without_OrderItem_have_expected_properties() {
        // Given
        let shippingLabel = MockShippingLabel.emptyLabel().copy(productIDs: [3013], productNames: ["Password protected!"])
        let imageURL = URL(string: "woocommerce.com/woocommerce.jpeg")!
        let variation = MockProductVariation().productVariation()
            .copy(productID: 100,
                  productVariationID: 3013,
                  image: createProductImage(src: imageURL.absoluteString),
                  price: "62")
        let aggregatedOrderItems = AggregatedShippingLabelOrderItems(shippingLabels: [shippingLabel],
                                                                     orderItems: [],
                                                                     products: [],
                                                                     productVariations: [variation])

        // When
        let shippingLabelOrderItems = aggregatedOrderItems.orderItems(of: shippingLabel)

        // Then
        XCTAssertEqual(shippingLabelOrderItems, [
            // The name falls back to the name in shipping label's `productNames`.
            .init(itemID: "0",
                  productID: 100,
                  variationID: 3013,
                  name: "Password protected!",
                  price: 62,
                  quantity: 1,
                  sku: variation.sku,
                  total: 62,
                  imageURL: imageURL,
                  attributes: [],
                  addOns: [],
                  parent: nil)
        ])
        XCTAssertEqual(shippingLabelOrderItems[0], aggregatedOrderItems.orderItem(of: shippingLabel, at: 0))
    }
}

private extension AggregatedShippingLabelOrderItemsTests {
    func createProductImage(src: String) -> ProductImage {
        .init(imageID: 0, dateCreated: Date(), dateModified: nil, src: src, name: nil, alt: nil)
    }
}
