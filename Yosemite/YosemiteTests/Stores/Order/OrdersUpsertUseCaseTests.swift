import XCTest

import Fakes
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

    func test_it_persists_order_item_addons_in_storage() throws {
        // Given
        let addOns = [
            Networking.OrderItemProductAddOn(addOnID: nil, key: "Is a gift", value: "Yes"),
            Networking.OrderItemProductAddOn(addOnID: 685, key: "Has logo", value: "No")
        ]
        let orderItem = OrderItem.fake().copy(itemID: 76, addOns: addOns)
        let order = Order.fake().copy(siteID: 3, orderID: 98, items: [orderItem])
        let useCase = OrdersUpsertUseCase(storage: viewStorage)

        // When
        useCase.upsert([order])

        // Then
        let storageOrderItem = try XCTUnwrap(viewStorage.loadOrderItem(siteID: 3, orderID: 98, itemID: 76))
        XCTAssertEqual(storageOrderItem.toReadOnly(), orderItem)
        XCTAssertEqual(storageOrderItem.toReadOnly().addOns, addOns)
    }

    func test_it_replaces_existing_order_item_addons_in_storage() throws {
        // Given
        let originalAddOns = [Networking.OrderItemProductAddOn(addOnID: 685, key: "Extra cheese", value: "Parmasan")]
        let originalOrderItem = OrderItem.fake().copy(itemID: 76, addOns: originalAddOns)
        let order = Order.fake().copy(siteID: 3, orderID: 98, items: [originalOrderItem])
        let useCase = OrdersUpsertUseCase(storage: viewStorage)
        useCase.upsert([order])

        // When
        let addOns = [
            Networking.OrderItemProductAddOn(addOnID: nil, key: "Extra cheese", value: "Emmental"),
            Networking.OrderItemProductAddOn(addOnID: 685, key: "Hot pepper", value: "Yes")
        ]
        let orderItem = OrderItem.fake().copy(itemID: 76, addOns: addOns)
        useCase.upsert([order.copy(items: [orderItem])])

        // Then
        let storageOrderItem = try XCTUnwrap(viewStorage.loadOrderItem(siteID: 3, orderID: 98, itemID: 76))
        XCTAssertEqual(storageOrderItem.toReadOnly(), orderItem)
        XCTAssertEqual(storageOrderItem.toReadOnly().addOns, addOns)
    }

    func test_it_persists_order_custom_field_in_storage() throws {
        // Given
        let customField = MetaData(metadataID: 1, key: "Key", value: "Value")
        let order = makeOrder().copy(siteID: 3, customFields: [customField])
        let useCase = OrdersUpsertUseCase(storage: viewStorage)

        // When
        useCase.upsert([order])

        // Then
        let storageCustomField = try XCTUnwrap(viewStorage.loadMetaData(siteID: 3, metadataID: 1))
        XCTAssertEqual(storageCustomField.toReadOnly(), customField)
    }

    func test_it_replaces_existing_order_custom_field_in_storage() throws {
        // Given
        let originalCustomField = MetaData(metadataID: 1, key: "Key", value: "Value")
        let order = makeOrder().copy(siteID: 3, customFields: [originalCustomField])
        let useCase = OrdersUpsertUseCase(storage: viewStorage)
        useCase.upsert([order])

        // When
        let customField = MetaData(metadataID: 1, key: "Key", value: "New Value")
        useCase.upsert([order.copy(customFields: [customField])])

        // Then
        let storageCustomField = try XCTUnwrap(viewStorage.loadMetaData(siteID: 3, metadataID: 1))
        XCTAssertEqual(storageCustomField.toReadOnly(), customField)
    }

    func test_it_persists_order_gift_card_in_storage() throws {
        // Given
        let giftCard = OrderGiftCard(giftCardID: 2, code: "SU9F-MGB5-KS5V-EZFT", amount: 20)
        let order = makeOrder().copy(siteID: 3, orderID: 11, appliedGiftCards: [giftCard])
        let useCase = OrdersUpsertUseCase(storage: viewStorage)

        // When
        useCase.upsert([order])

        // Then
        let storageOrder = try XCTUnwrap(viewStorage.loadOrder(siteID: 3, orderID: 11))
        XCTAssertEqual(storageOrder.appliedGiftCards?.map { $0.toReadOnly() }, [giftCard])
    }

    func test_it_replaces_existing_order_gift_card_in_storage_for_the_same_order() throws {
        // Given
        let originalGiftCard = OrderGiftCard(giftCardID: 2, code: "SU9F-MGB5-KS5V-EZFT", amount: 20)
        let order = makeOrder().copy(siteID: 3, orderID: 11, appliedGiftCards: [originalGiftCard])
        let useCase = OrdersUpsertUseCase(storage: viewStorage)
        useCase.upsert([order])

        // When
        let giftCard = OrderGiftCard(giftCardID: 2, code: "SU9F-MGB5-KS5V-EZFT", amount: 25)
        useCase.upsert([order.copy(appliedGiftCards: [giftCard])])

        // Then
        let storageOrder = try XCTUnwrap(viewStorage.loadOrder(siteID: 3, orderID: 11))
        XCTAssertEqual(storageOrder.appliedGiftCards?.map { $0.toReadOnly() }, [giftCard])
    }

    func test_it_does_not_replace_existing_order_gift_card_in_storage_for_a_different_order() throws {
        // Given
        let originalGiftCard = OrderGiftCard(giftCardID: 2, code: "SU9F-MGB5-KS5V-EZFT", amount: 20)
        let originalOrder = makeOrder().copy(siteID: 3, orderID: 11, appliedGiftCards: [originalGiftCard])
        let useCase = OrdersUpsertUseCase(storage: viewStorage)
        useCase.upsert([originalOrder])

        // When
        let giftCard = OrderGiftCard(giftCardID: 2, code: "SU9F-MGB5-KS5V-EZFT", amount: 25)
        let order = makeOrder().copy(siteID: 3, orderID: 12, appliedGiftCards: [giftCard])
        useCase.upsert([order])

        // Then
        let originalStorageOrder = try XCTUnwrap(viewStorage.loadOrder(siteID: 3, orderID: 11))
        XCTAssertEqual(originalStorageOrder.appliedGiftCards?.map { $0.toReadOnly() }, [originalGiftCard])
        let storageOrder = try XCTUnwrap(viewStorage.loadOrder(siteID: 3, orderID: 12))
        XCTAssertEqual(storageOrder.appliedGiftCards?.map { $0.toReadOnly() }, [giftCard])
    }

    func test_it_allows_multiple_gift_cards_of_the_same_giftCardID_for_the_same_order_in_storage() throws {
        // Given
        let giftCard1 = OrderGiftCard(giftCardID: 2, code: "SU9F-MGB5-KS5V-EZFT", amount: 25)
        let giftCard2 = OrderGiftCard(giftCardID: 2, code: "SU9F-MGB5-KS5V-EZFT", amount: 5)
        let order = makeOrder().copy(siteID: 3, orderID: 11, appliedGiftCards: [giftCard1, giftCard2])

        // When
        let useCase = OrdersUpsertUseCase(storage: viewStorage)
        useCase.upsert([order])

        // Then
        let storageOrder = try XCTUnwrap(viewStorage.loadOrder(siteID: 3, orderID: 11))
        // `appliedGiftCards` is a Set and sorting is required to guarantee the order.
        XCTAssertEqual(storageOrder.appliedGiftCards?.map { $0.toReadOnly() }.sorted(by: { $0.amount > $1.amount }),
                       [giftCard1, giftCard2])
    }

    func test_it_persists_order_attribution_info_in_storage() throws {
        // Given
        let attributionInfo = OrderAttributionInfo.fake()
        let order = makeOrder().copy(siteID: 3, orderID: 11, attributionInfo: attributionInfo)
        let useCase = OrdersUpsertUseCase(storage: viewStorage)

        // When
        useCase.upsert([order])

        // Then
        let storageAttributionInfo = try XCTUnwrap(viewStorage.loadOrder(siteID: 3, orderID: 11)?.attributionInfo)
        XCTAssertEqual(storageAttributionInfo.toReadOnly(), attributionInfo)
    }

    func test_it_replaces_existing_order_attribution_info_in_storage() throws {
        // Given
        let originalAttributionInfo = OrderAttributionInfo.fake().copy(source: "admin")
        let order = makeOrder().copy(siteID: 3, orderID: 11, attributionInfo: originalAttributionInfo)
        let useCase = OrdersUpsertUseCase(storage: viewStorage)
        useCase.upsert([order])

        // When
        let attributionInfo = OrderAttributionInfo.fake().copy(source: "blaze")
        useCase.upsert([order.copy(attributionInfo: attributionInfo)])

        // Then
        let storageAttributionInfo = try XCTUnwrap(viewStorage.loadOrder(siteID: 3, orderID: 11)?.attributionInfo)
        XCTAssertEqual(storageAttributionInfo.toReadOnly(), attributionInfo)
    }

    func test_it_removes_existing_order_attribution_info_from_storage_if_removed_in_remote() throws {
        // Given
        let siteID: Int64 = 3
        let orderID: Int64 = 11
        let originalAttributionInfo = OrderAttributionInfo.fake().copy(source: "admin")
        let order = makeOrder().copy(siteID: siteID, orderID: orderID, attributionInfo: originalAttributionInfo)
        let useCase = OrdersUpsertUseCase(storage: viewStorage)
        useCase.upsert([order])

        // When
        useCase.upsert([order.copy(attributionInfo: .some(nil))])

        // Then
        XCTAssertNil(viewStorage.loadOrderAttributionInfo(siteID: siteID, orderID: orderID))
        let storageOrder = try XCTUnwrap(viewStorage.loadOrder(siteID: siteID, orderID: orderID))
        XCTAssertNil(storageOrder.attributionInfo)
    }

    func test_it_removes_existing_order_items_from_storage_if_removed_in_remote() throws {
        // Given
        let orderID: Int64 = 11
        let itemID: Int64 = 22
        let item = makeOrderItem(itemID: itemID)
        let order = makeOrder().copy(orderID: orderID, items: [item])
        let useCase = OrdersUpsertUseCase(storage: viewStorage)
        useCase.upsert([order])

        // When
        useCase.upsert([order.copy(items: [])])

        // Then
        XCTAssertNil(viewStorage.loadOrderItem(siteID: defaultSiteID, orderID: orderID, itemID: itemID))
        let storageOrder = try XCTUnwrap(viewStorage.loadOrder(siteID: defaultSiteID, orderID: orderID))
        XCTAssertEqual(0, storageOrder.items?.count)
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
                  parent: nil,
                  bundleConfiguration: [])
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
              parent: nil,
              bundleConfiguration: [])
    }
}
