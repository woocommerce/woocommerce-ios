import XCTest

import Storage
import Networking

@testable import Yosemite

final class OrdersUpsertUseCaseTests: XCTestCase {

    private let defaultSiteID: Int64 = 10
    private var storageManager: StorageManagerType!
    private var viewStorage: StorageType {
        storageManager.viewStorage
    }

    override func setUp() {
        super.setUp()
        storageManager = MockStorageManager()
    }

    override func tearDown() {
        storageManager = nil
        super.tearDown()
    }

    func test_it_inserts_orders_with_permanent_ids() throws {
        // Given
        let orders = [makeOrder(), makeOrder()]
        let useCase = OrdersUpsertUseCase(storage: viewStorage)

        // When
        let storageOrders = useCase.upsert(orders)

        // Then
        XCTAssertEqual(storageOrders.count, 2)
        storageOrders.forEach { storageOrder in
            XCTAssertFalse(storageOrder.objectID.isTemporaryID)
        }
    }

    func test_it_persists_orders_in_storage() throws {
        // Given
        let orders = [
            makeOrder().copy(orderID: 98, number: "dignissimos"),
            makeOrder().copy(orderID: 9001, number: "omnis"),
        ]
        let useCase = OrdersUpsertUseCase(storage: viewStorage)

        // When
        useCase.upsert(orders)

        // Then
        let persistedOrder98 = try XCTUnwrap(viewStorage.loadOrder(siteID: defaultSiteID, orderID: 98))
        XCTAssertEqual(persistedOrder98.toReadOnly(), orders.first)

        let persistedOrder9001 = try XCTUnwrap(viewStorage.loadOrder(siteID: defaultSiteID, orderID: 9001))
        XCTAssertEqual(persistedOrder9001.toReadOnly(), orders.last)
    }

    func test_it_persists_order_relationships_in_storage() throws {
        // Given
        let coupon = Networking.OrderCouponLine(couponID: 1, code: "", discount: "", discountTax: "")
        let refund = Networking.OrderRefundCondensed(refundID: 122, reason: "", total: "1.6")
        let shippingLine = Networking.ShippingLine(shippingID: 25, methodTitle: "dodo", methodID: "", total: "2.1", totalTax: "0.8", taxes: [])
        let order = makeOrder().copy(orderID: 98, number: "dignissimos", shippingLines: [shippingLine], coupons: [coupon], refunds: [refund])
        let useCase = OrdersUpsertUseCase(storage: viewStorage)

        // When
        useCase.upsert([order])

        // Then
        let persistedOrder = try XCTUnwrap(viewStorage.loadOrder(siteID: defaultSiteID, orderID: 98))
        XCTAssertEqual(persistedOrder.toReadOnly(), order)
        let persistedCoupon = try XCTUnwrap(viewStorage.loadOrderCoupon(siteID: defaultSiteID, couponID: coupon.couponID))
        XCTAssertEqual(persistedCoupon.toReadOnly(), coupon)
        let persistedRefund = try XCTUnwrap(viewStorage.loadOrderRefundCondensed(siteID: defaultSiteID, refundID: refund.refundID))
        XCTAssertEqual(persistedRefund.toReadOnly(), refund)
        let persistedShippingLine = try XCTUnwrap(viewStorage.loadOrderShippingLine(siteID: defaultSiteID, shippingID: shippingLine.shippingID))
        XCTAssertEqual(persistedShippingLine.toReadOnly(), shippingLine)
    }

    func test_it_persists_order_item_taxes_in_storage() throws {
        // Given
        let taxes = [
            Networking.OrderItemTax(taxID: 2, subtotal: "", total: "0.2"),
            Networking.OrderItemTax(taxID: 3, subtotal: "", total: "0.6")
        ]
        let item = makeOrderItem(itemID: 22, taxes: taxes)
        let order = makeOrder().copy(orderID: 98).copy(items: [item])
        let useCase = OrdersUpsertUseCase(storage: viewStorage)

        // When
        useCase.upsert([order])

        // Then
        let tax1 = try XCTUnwrap(viewStorage.loadOrderItemTax(itemID: 22, taxID: 2))
        XCTAssertEqual(tax1.toReadOnly(), taxes[0])

        let tax2 = try XCTUnwrap(viewStorage.loadOrderItemTax(itemID: 22, taxID: 3))
        XCTAssertEqual(tax2.toReadOnly(), taxes[1])
    }

    func test_it_persists_shipping_line_taxes_in_storage() throws {
        // Given
        let taxes = [
            Networking.ShippingLineTax(taxID: 2, subtotal: "", total: "0.2"),
            Networking.ShippingLineTax(taxID: 3, subtotal: "", total: "0.6")
        ]
        let shippingLine = Networking.ShippingLine(shippingID: 25, methodTitle: "dodo", methodID: "", total: "2.1", totalTax: "0.8", taxes: taxes)
        let order = makeOrder().copy(orderID: 98, shippingLines: [shippingLine])
        let useCase = OrdersUpsertUseCase(storage: viewStorage)

        // When
        useCase.upsert([order])

        // Then
        let tax1 = try XCTUnwrap(viewStorage.loadShippingLineTax(shippingID: 25, taxID: 2))
        XCTAssertEqual(tax1.toReadOnly(), taxes[0])

        let tax2 = try XCTUnwrap(viewStorage.loadShippingLineTax(shippingID: 25, taxID: 3))
        XCTAssertEqual(tax2.toReadOnly(), taxes[1])
    }

    func test_it_persists_order_tax_line_in_storage() throws {
        // Given
        let taxLine = OrderTaxLine.fake().copy(taxID: 1)
        let order = makeOrder().copy(siteID: 3, taxes: [taxLine])
        let useCase = OrdersUpsertUseCase(storage: viewStorage)

        // When
        useCase.upsert([order])

        // Then
        let storageTaxLine = try XCTUnwrap(viewStorage.loadOrderTaxLine(siteID: 3, taxID: 1))
        XCTAssertEqual(storageTaxLine.toReadOnly(), taxLine)
    }

    func test_it_replaces_existing_order_tax_line_in_storage() throws {
        // Given
        let originalTaxLine = OrderTaxLine.fake().copy(taxID: 1, ratePercent: 0.0)
        let order = makeOrder().copy(siteID: 3, taxes: [originalTaxLine])
        let useCase = OrdersUpsertUseCase(storage: viewStorage)
        useCase.upsert([order])

        // When
        let taxLine = OrderTaxLine.fake().copy(taxID: 1, ratePercent: 5.0)
        useCase.upsert([order.copy(taxes: [taxLine])])

        // Then
        let storageTaxLine = try XCTUnwrap(viewStorage.loadOrderTaxLine(siteID: 3, taxID: 1))
        XCTAssertEqual(storageTaxLine.toReadOnly(), taxLine)
    }

    func test_it_persists_order_item_attributes_in_storage() throws {
        // Given
        let attributes = [
            Networking.OrderItemAttribute(metaID: 2, name: "Type", value: "Water"),
            Networking.OrderItemAttribute(metaID: 2, name: "Strong against", value: "Fire")
        ]
        let orderItem = makeOrderItem(itemID: 76, attributes: attributes)
        let order = makeOrder().copy(siteID: 3, orderID: 98, items: [orderItem])
        let useCase = OrdersUpsertUseCase(storage: viewStorage)

        // When
        useCase.upsert([order])

        // Then
        let storageOrderItem = try XCTUnwrap(viewStorage.loadOrderItem(siteID: 3, orderID: 98, itemID: 76))
        XCTAssertEqual(storageOrderItem.toReadOnly(), orderItem)
    }

    func test_it_replaces_existing_order_item_attributes_in_storage() throws {
        // Given
        let originalAttributes = [Networking.OrderItemAttribute(metaID: 2, name: "Type", value: "Water")]
        let originalOrderItem = makeOrderItem(itemID: 76, attributes: originalAttributes)
        let order = makeOrder().copy(siteID: 3, orderID: 98, items: [originalOrderItem])
        let useCase = OrdersUpsertUseCase(storage: viewStorage)
        useCase.upsert([order])

        // When
        let attributes = [
            Networking.OrderItemAttribute(metaID: 2, name: "Type", value: "Flying"),
            Networking.OrderItemAttribute(metaID: 2, name: "Strong against", value: "Rock")
        ]
        let orderItem = makeOrderItem(itemID: 76, attributes: attributes)
        useCase.upsert([order.copy(items: [orderItem])])

        // Then
        let storageOrderItem = try XCTUnwrap(viewStorage.loadOrderItem(siteID: 3, orderID: 98, itemID: 76))
        XCTAssertEqual(storageOrderItem.toReadOnly(), orderItem)
    }

    func test_it_persists_order_custom_field_in_storage() throws {
        // Given
        let customField = OrderMetaData(metadataID: 1, key: "Key", value: "Value")
        let order = makeOrder().copy(siteID: 3, customFields: [customField])
        let useCase = OrdersUpsertUseCase(storage: viewStorage)

        // When
        useCase.upsert([order])

        // Then
        let storageCustomField = try XCTUnwrap(viewStorage.loadOrderMetaData(siteID: 3, metadataID: 1))
        XCTAssertEqual(storageCustomField.toReadOnly(), customField)
    }

    func test_it_replaces_existing_order_custom_field_in_storage() throws {
        // Given
        let originalCustomField = OrderMetaData(metadataID: 1, key: "Key", value: "Value")
        let order = makeOrder().copy(siteID: 3, customFields: [originalCustomField])
        let useCase = OrdersUpsertUseCase(storage: viewStorage)
        useCase.upsert([order])

        // When
        let customField = OrderMetaData(metadataID: 1, key: "Key", value: "New Value")
        useCase.upsert([order.copy(customFields: [customField])])

        // Then
        let storageCustomField = try XCTUnwrap(viewStorage.loadOrderMetaData(siteID: 3, metadataID: 1))
        XCTAssertEqual(storageCustomField.toReadOnly(), customField)
    }

    func test_it_persists_order_gift_card_in_storage() throws {
        // Given
        let giftCard = OrderGiftCard(giftCardID: 2, code: "SU9F-MGB5-KS5V-EZFT", amount: 20)
        let order = makeOrder().copy(siteID: 3, appliedGiftCards: [giftCard])
        let useCase = OrdersUpsertUseCase(storage: viewStorage)

        // When
        useCase.upsert([order])

        // Then
        let storageGiftCard = try XCTUnwrap(viewStorage.loadOrderGiftCard(siteID: 3, giftCardID: 2))
        XCTAssertEqual(storageGiftCard.toReadOnly(), giftCard)
    }

    func test_it_replaces_existing_order_gift_card_in_storage() throws {
        // Given
        let originalGiftCard = OrderGiftCard(giftCardID: 2, code: "SU9F-MGB5-KS5V-EZFT", amount: 20)
        let order = makeOrder().copy(siteID: 3, appliedGiftCards: [originalGiftCard])
        let useCase = OrdersUpsertUseCase(storage: viewStorage)
        useCase.upsert([order])

        // When
        let giftCard = OrderGiftCard(giftCardID: 2, code: "SU9F-MGB5-KS5V-EZFT", amount: 25)
        useCase.upsert([order.copy(appliedGiftCards: [giftCard])])

        // Then
        let storageGiftCard = try XCTUnwrap(viewStorage.loadOrderGiftCard(siteID: 3, giftCardID: 2))
        XCTAssertEqual(storageGiftCard.toReadOnly(), giftCard)
    }
}

private extension OrdersUpsertUseCaseTests {

    func makeOrderItem(itemID: Int64, taxes: [Networking.OrderItemTax]) -> Networking.OrderItem {
        OrderItem(itemID: itemID,
                  name: "",
                  productID: 0,
                  variationID: 0,
                  quantity: 0,
                  price: 0,
                  sku: nil,
                  subtotal: "",
                  subtotalTax: "",
                  taxClass: "",
                  taxes: taxes,
                  total: "",
                  totalTax: "",
                  attributes: [],
                  addOns: [],
                  parent: nil)
    }

    func makeOrder() -> Networking.Order {
        Order.fake().copy(siteID: defaultSiteID, customerNote: "", items: [])
    }

    func makeOrderItem(itemID: Int64 = 76, attributes: [Networking.OrderItemAttribute] = []) -> Networking.OrderItem {
        .init(itemID: itemID,
              name: "Poke",
              productID: 22,
              variationID: 0,
              quantity: -1,
              price: 18,
              sku: "poke-month",
              subtotal: "-18.0",
              subtotalTax: "0.00",
              taxClass: "",
              taxes: [],
              total: "-18.00",
              totalTax: "0.00",
              attributes: attributes,
              addOns: [],
              parent: nil)
    }
}
