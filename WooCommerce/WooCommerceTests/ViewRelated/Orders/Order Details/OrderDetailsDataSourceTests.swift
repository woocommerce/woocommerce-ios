import Foundation
import XCTest

import Yosemite
import WooFoundation

import protocol Storage.StorageManagerType
import protocol Storage.StorageType

@testable import WooCommerce

/// Test cases for `OrderDetailsDataSourceTests`
///
final class OrderDetailsDataSourceTests: XCTestCase {

    private typealias Title = OrderDetailsDataSource.Title

    private var storageManager: MockStorageManager!

    private var storage: StorageType {
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

    func test_payment_section_is_shown_right_after_the_products_and_refunded_products_sections() {
        // Given
        let order = makeOrder()

        insert(refund: makeRefund(orderID: order.orderID, siteID: order.siteID))

        let dataSource = OrderDetailsDataSource(
            order: order,
            storageManager: storageManager,
            cardPresentPaymentsConfiguration: Mocks.configuration
        )

        dataSource.configureResultsControllers { }

        // When
        dataSource.reloadSections()

        // Then
        let actualTitles = dataSource.sections.map(\.title)
        let expectedTitles = [
            nil,
            Title.products,
            Title.refundedProducts,
            Title.payment,
            Title.information,
            Title.notes
        ]

        XCTAssertEqual(actualTitles, expectedTitles)
    }

    func test_reloadSections_when_there_is_no_paid_date_then_customer_paid_row_is_visible() throws {
        // Given
        let order = Order.fake()
        let dataSource = OrderDetailsDataSource(order: order, storageManager: storageManager, cardPresentPaymentsConfiguration: Mocks.configuration)

        // When
        dataSource.reloadSections()

        // Then
        let paymentSection = try section(withTitle: Title.payment, from: dataSource)
        let customerPaidRow = row(row: .customerPaid, in: paymentSection)
        XCTAssertNotNil(customerPaidRow)
    }

    func test_reloadSections_when_there_is_a_paid_date_then_customer_paid_row_is_visible() throws {
        // Given
        let order = Order.fake().copy(datePaid: Date())
        let dataSource = OrderDetailsDataSource(order: order, storageManager: storageManager, cardPresentPaymentsConfiguration: Mocks.configuration)

        // When
        dataSource.reloadSections()

        // Then
        let paymentSection = try section(withTitle: Title.payment, from: dataSource)
        let customerPaidRow = row(row: .customerPaid, in: paymentSection)
        XCTAssertNotNil(customerPaidRow)
    }

    func test_refund_button_is_visible() throws {
        // Given
        let order = makeOrder()
        let dataSource = OrderDetailsDataSource(order: order, storageManager: storageManager, cardPresentPaymentsConfiguration: Mocks.configuration)

        // When
        dataSource.reloadSections()

        // Then
        let paymentSection = try section(withTitle: Title.payment, from: dataSource)
        let issueRefundRow = row(row: .issueRefundButton, in: paymentSection)
        XCTAssertNotNil(issueRefundRow)
    }

    func test_refund_button_is_not_visible_when_there_is_no_date_paid() throws {
        // Given
        let order = makeOrder().copy(datePaid: .some(nil))
        let orderRefundsOptionsDeterminer = MockOrderRefundsOptionsDeterminer(isAnythingToRefund: true)
        let dataSource = OrderDetailsDataSource(order: order,
                                                storageManager: storageManager,
                                                cardPresentPaymentsConfiguration: Mocks.configuration,
                                                refundableOrderItemsDeterminer: orderRefundsOptionsDeterminer)

        // When
        dataSource.reloadSections()

        // Then
        let paymentSection = try section(withTitle: Title.payment, from: dataSource)
        let issueRefundRow = row(row: .issueRefundButton, in: paymentSection)
        XCTAssertNil(issueRefundRow)
    }

    func test_refund_button_is_not_visible_when_the_order_status_is_refunded() throws {
        // Given
        let order = MockOrders().makeOrder(status: .refunded, items: [makeOrderItem()])
        let dataSource = OrderDetailsDataSource(order: order, storageManager: storageManager, cardPresentPaymentsConfiguration: Mocks.configuration)

        // When
        dataSource.reloadSections()

        // Then
        let paymentSection = try section(withTitle: Title.payment, from: dataSource)
        let issueRefundRow = row(row: .issueRefundButton, in: paymentSection)
        XCTAssertNil(issueRefundRow)
    }

    func test_refund_button_is_not_visible_when_the_status_is_other_than_refunded_but_the_order_is_not_refundable() throws {
        // Given
        let order = Order.fake().copy(status: .processing, items: [makeOrderItem()], refunds: [OrderRefundCondensed.fake()])
        let orderRefundsOptionsDeterminer = MockOrderRefundsOptionsDeterminer(isAnythingToRefund: false)
        let dataSource = OrderDetailsDataSource(order: order,
                                                storageManager: storageManager,
                                                cardPresentPaymentsConfiguration: Mocks.configuration,
                                                refundableOrderItemsDeterminer: orderRefundsOptionsDeterminer)

        // When
        dataSource.reloadSections()

        // Then
        let paymentSection = try section(withTitle: Title.payment, from: dataSource)
        let issueRefundRow = row(row: .issueRefundButton, in: paymentSection)
        XCTAssertNil(issueRefundRow)
    }

    func test_markOrderComplete_button_is_visible_and_primary_style_if_order_is_processing_and_not_eligible_for_shipping_label_creation() throws {
        // Given
        let order = makeOrder().copy(status: .processing)
        let dataSource = OrderDetailsDataSource(order: order, storageManager: storageManager, cardPresentPaymentsConfiguration: Mocks.configuration)
        dataSource.isEligibleForShippingLabelCreation = false

        // When
        dataSource.reloadSections()

        // Then
        let productsSection = try section(withTitle: Title.products, from: dataSource)
        XCTAssertNotNil(row(row: .markCompleteButton(style: .primary, showsBottomSpacing: true), in: productsSection))
    }

    func test_markOrderComplete_button_is_visible_and_secondary_style_if_order_is_processing_and_eligible_for_shipping_label_creation() throws {
        // Given
        let order = makeOrder().copy(status: .processing)
        let dataSource = OrderDetailsDataSource(order: order, storageManager: storageManager, cardPresentPaymentsConfiguration: Mocks.configuration)
        dataSource.isEligibleForShippingLabelCreation = true

        // When
        dataSource.reloadSections()

        // Then
        let productsSection = try section(withTitle: Title.products, from: dataSource)
        XCTAssertNotNil(row(row: .markCompleteButton(style: .secondary, showsBottomSpacing: false), in: productsSection))
        XCTAssertNotNil(row(row: .shippingLabelCreationInfo(showsSeparator: false), in: productsSection))
    }

    func test_markOrderComplete_button_is_hidden_if_order_is_not_processing() throws {
        // Given
        let order = makeOrder().copy(status: .onHold)
        let dataSource = OrderDetailsDataSource(order: order, storageManager: storageManager, cardPresentPaymentsConfiguration: Mocks.configuration)

        // When
        dataSource.reloadSections()

        // Then
        let productsSection = try section(withTitle: Title.products, from: dataSource)
        XCTAssertNil(row(row: .markCompleteButton(style: .primary, showsBottomSpacing: true), in: productsSection))
        XCTAssertNil(row(row: .markCompleteButton(style: .secondary, showsBottomSpacing: false), in: productsSection))
    }

    func test_reloadSections_when_isEligibleForPayment_is_false_then_collect_payment_button_is_not_visible() throws {
        //Given
        let order = makeOrder().copy(datePaid: .some(Date())) // Paid orders are not eligible for payment
        let dataSource = OrderDetailsDataSource(order: order, storageManager: storageManager, cardPresentPaymentsConfiguration: Mocks.configuration)

        // When
        dataSource.reloadSections()

        // Then
        let paymentSection = try section(withTitle: Title.payment, from: dataSource)
        XCTAssertNil(row(row: .collectCardPaymentButton, in: paymentSection))
    }

    func test_reloadSections_when_isEligibleForPayment_is_true_then_collect_payment_button_is_visible() throws {
        //Given
        let order = makeOrder().copy(needsPayment: true) // Unpaid orders are eligible for payment
        let dataSource = OrderDetailsDataSource(order: order, storageManager: storageManager, cardPresentPaymentsConfiguration: Mocks.configuration)

        // When
        dataSource.reloadSections()

        // Then
        let paymentSection = try section(withTitle: Title.payment, from: dataSource)
        XCTAssertNotNil(row(row: .collectCardPaymentButton, in: paymentSection))
    }

    func test_create_shipping_label_button_is_visible_for_eligible_order_with_no_labels() throws {
        // Given
        let order = makeOrder()
        let dataSource = OrderDetailsDataSource(order: order, storageManager: storageManager, cardPresentPaymentsConfiguration: Mocks.configuration)
        dataSource.isEligibleForShippingLabelCreation = true

        // When
        dataSource.reloadSections()

        // Then
        let productSection = try section(withTitle: Title.products, from: dataSource)
        let createShippingLabelRow = row(row: .shippingLabelCreateButton, in: productSection)
        XCTAssertNotNil(createShippingLabelRow)
    }

    func test_create_shipping_label_button_is_visible_for_eligible_order_with_only_refunded_labels() throws {
        // Given
        let order = makeOrder()
        let refundedShippingLabel = ShippingLabel.fake().copy(siteID: order.siteID, orderID: order.orderID, refund: ShippingLabelRefund.fake())
        insert(shippingLabel: refundedShippingLabel)

        let dataSource = OrderDetailsDataSource(order: order, storageManager: storageManager, cardPresentPaymentsConfiguration: Mocks.configuration)
        dataSource.isEligibleForShippingLabelCreation = true
        dataSource.configureResultsControllers { }

        // When
        dataSource.reloadSections()

        // Then
        let productSection = try section(withTitle: Title.products, from: dataSource)
        let createShippingLabelRow = row(row: .shippingLabelCreateButton, in: productSection)
        XCTAssertNotNil(createShippingLabelRow)
    }

    func test_create_shipping_label_button_is_not_visible_for_eligible_order_with_labels() throws {
        // Given
        let order = makeOrder()
        let shippingLabel = ShippingLabel.fake().copy(siteID: order.siteID, orderID: order.orderID)
        insert(shippingLabel: shippingLabel)

        let dataSource = OrderDetailsDataSource(order: order, storageManager: storageManager, cardPresentPaymentsConfiguration: Mocks.configuration)
        dataSource.isEligibleForShippingLabelCreation = true
        dataSource.configureResultsControllers { }

        // When
        dataSource.reloadSections()

        // Then
        let productSection = try section(withTitle: Title.products, from: dataSource)
        let createShippingLabelRow = row(row: .shippingLabelCreateButton, in: productSection)
        XCTAssertNil(createShippingLabelRow)
    }

    func test_create_shipping_label_button_is_not_visible_for_ineligible_order() throws {
        // Given
        let order = makeOrder()
        let dataSource = OrderDetailsDataSource(order: order, storageManager: storageManager, cardPresentPaymentsConfiguration: Mocks.configuration)
        dataSource.isEligibleForShippingLabelCreation = false

        // When
        dataSource.reloadSections()

        // Then
        let productSection = try section(withTitle: Title.products, from: dataSource)
        let createShippingLabelRow = row(row: .shippingLabelCreateButton, in: productSection)
        XCTAssertNil(createShippingLabelRow)
    }

    func test_create_shipping_label_button_is_not_visible_when_order_is_eligible_for_payment() throws {
        // Given
        let order = makeOrder().copy(needsPayment: true, status: .pending)
        let dataSource = OrderDetailsDataSource(order: order, storageManager: storageManager, cardPresentPaymentsConfiguration: Mocks.configuration)
        dataSource.isEligibleForShippingLabelCreation = true

        // When
        dataSource.configureResultsControllers { }
        dataSource.reloadSections()

        // Then
        let productSection = try section(withTitle: Title.products, from: dataSource)
        let createShippingLabelRow = row(row: .shippingLabelCreateButton, in: productSection)
        XCTAssertNil(createShippingLabelRow)
    }

    func test_more_button_is_visible_in_product_section_for_eligible_order_without_refunded_labels() throws {
        // Given
        let order = makeOrder()
        let shippingLabel = ShippingLabel.fake().copy(siteID: order.siteID, orderID: order.orderID)
        insert(shippingLabel: shippingLabel)

        let dataSource = OrderDetailsDataSource(order: order, storageManager: storageManager, cardPresentPaymentsConfiguration: Mocks.configuration)
        dataSource.isEligibleForShippingLabelCreation = true
        dataSource.configureResultsControllers { }

        // When
        dataSource.reloadSections()

        // Then
        let productSection = try section(withTitle: Title.products, from: dataSource)
        guard case .actionablePrimary = productSection.headerStyle else {
            XCTFail("Product section should show more button on the header for eligible order without refunded labels")
            return
        }
    }

    func test_WCShip_installation_section_is_not_visible_when_WCShip_plugin_is_installed_and_active() throws {
        // Given
        let sampleSiteID: Int64 = 1234
        let order = makeOrder()
        let activePlugin = SitePlugin.fake().copy(siteID: sampleSiteID, status: .active, name: SitePlugin.SupportedPlugin.WCShip)
        insert(activePlugin)

        let currencySettings = CurrencySettings(currencyCode: .USD,
                                                currencyPosition: .leftSpace,
                                                thousandSeparator: "",
                                                decimalSeparator: ".",
                                                numberOfDecimals: 3)
        let siteSetting = SiteSetting.fake()
            .copy(
                siteID: sampleSiteID,
                settingID: "woocommerce_default_country",
                value: SiteAddress.CountryCode.US.rawValue,
                settingGroupKey: SiteSettingGroup.general.rawValue
            )

        let dataSource = OrderDetailsDataSource(order: order,
                                                storageManager: storageManager,
                                                cardPresentPaymentsConfiguration: Mocks.configuration,
                                                currencySettings: currencySettings,
                                                siteSettings: [siteSetting], featureFlags: MockFeatureFlagService(shippingLabelsOnboardingM1: true))
        dataSource.configureResultsControllers { }

        // When
        dataSource.reloadSections()

        // Then
        let wcShipSection = section(withCategory: .installWCShip, from: dataSource)
        XCTAssertNil(wcShipSection)
    }

    func test_WCShip_installation_section_is_visible_for_eligible_order() throws {
        // Given
        let sampleSiteID: Int64 = 1234
        let order = makeOrder()

        let currencySettings = CurrencySettings(currencyCode: .USD,
                                                currencyPosition: .leftSpace,
                                                thousandSeparator: "",
                                                decimalSeparator: ".",
                                                numberOfDecimals: 3)
        let siteSetting = SiteSetting.fake()
            .copy(
                siteID: sampleSiteID,
                settingID: "woocommerce_default_country",
                value: SiteAddress.CountryCode.US.rawValue,
                settingGroupKey: SiteSettingGroup.general.rawValue
            )

        let dataSource = OrderDetailsDataSource(order: order,
                                                storageManager: storageManager,
                                                cardPresentPaymentsConfiguration: CardPresentPaymentsConfiguration(country: "US"),
                                                currencySettings: currencySettings,
                                                siteSettings: [siteSetting],
                                                userIsAdmin: true,
                                                featureFlags: MockFeatureFlagService(shippingLabelsOnboardingM1: true))
        dataSource.configureResultsControllers { }

        // When
        dataSource.reloadSections()

        // Then
        guard let wcShipSection = section(withCategory: .installWCShip, from: dataSource) else {
            XCTFail("WCShip install section should be visible")
            return
        }
        let wcShipRow = row(row: .installWCShip, in: wcShipSection)
        XCTAssertNotNil(wcShipRow)
    }

    func test_more_button_is_visible_in_product_section_for_eligible_order_with_refunded_labels() throws {
        // Given
        let order = makeOrder()
        let refundedShippingLabel = ShippingLabel.fake().copy(siteID: order.siteID, orderID: order.orderID, refund: ShippingLabelRefund.fake())
        insert(shippingLabel: refundedShippingLabel)

        let dataSource = OrderDetailsDataSource(order: order, storageManager: storageManager, cardPresentPaymentsConfiguration: Mocks.configuration)
        dataSource.isEligibleForShippingLabelCreation = true
        dataSource.configureResultsControllers { }

        // When
        dataSource.reloadSections()

        // Then
        let productSection = try section(withTitle: Title.products, from: dataSource)
        guard case .actionablePrimary = productSection.headerStyle else {
            XCTFail("Product section should show more button on the header for eligible order with refunded labels")
            return
        }
    }

    func test_more_button_is_not_visible_in_product_section_for_eligible_order_without_shipping_labels() throws {
        // Given
        let order = makeOrder()

        let dataSource = OrderDetailsDataSource(order: order, storageManager: storageManager, cardPresentPaymentsConfiguration: Mocks.configuration)
        dataSource.isEligibleForShippingLabelCreation = true
        dataSource.configureResultsControllers { }

        // When
        dataSource.reloadSections()

        // Then
        let productSection = try section(withTitle: Title.products, from: dataSource)
        guard case .primary = productSection.headerStyle else {
            XCTFail("Product section should not show button on the header for eligible order without shipping labels")
            return
        }
    }

    func test_more_button_is_not_visible_in_product_section_for_ineligible_order() throws {
        // Given
        let order = makeOrder()

        let dataSource = OrderDetailsDataSource(order: order, storageManager: storageManager, cardPresentPaymentsConfiguration: Mocks.configuration)
        dataSource.isEligibleForShippingLabelCreation = false
        dataSource.configureResultsControllers { }

        // When
        dataSource.reloadSections()

        // Then
        let productSection = try section(withTitle: Title.products, from: dataSource)
        guard case .primary = productSection.headerStyle else {
            XCTFail("Product section should not show button on the header for ineligible order")
            return
        }
    }

    func test_more_button_is_not_visible_in_product_section_for_cash_on_delivery_order() throws {
        // Given
        let order = makeOrder().copy(status: .processing, datePaid: .some(nil), total: "100", paymentMethodID: "cod")
        let dataSource = OrderDetailsDataSource(order: order, storageManager: storageManager, cardPresentPaymentsConfiguration: Mocks.configuration)
        dataSource.isEligibleForShippingLabelCreation = true

        // When
        dataSource.configureResultsControllers { }
        dataSource.reloadSections()

        // Then
        let productSection = try section(withTitle: Title.products, from: dataSource)
        guard case .primary = productSection.headerStyle else {
            XCTFail("Product section should not show button on the header for cash on delivery order")
            return
        }
    }

    func test_custom_fields_button_is_visible() throws {
        // Given
        let order = MockOrders().makeOrder(customFields: [
            OrderMetaData(metadataID: 123, key: "Key", value: "Value")
        ])
        let dataSource = OrderDetailsDataSource(
            order: order, storageManager: storageManager,
            cardPresentPaymentsConfiguration: Mocks.configuration
        )

        // When
        dataSource.reloadSections()

        // Then
        let customFieldSection = section(withCategory: .customFields, from: dataSource)
        XCTAssertNotNil(customFieldSection)
    }

    func test_custom_fields_button_is_hidden_when_order_contains_no_custom_fields_to_display() throws {
        // Given
        let order = MockOrders().makeOrder(customFields: [])
        let dataSource = OrderDetailsDataSource(
            order: order, storageManager: storageManager,
            cardPresentPaymentsConfiguration: Mocks.configuration
        )

        // When
        dataSource.reloadSections()

        // Then
        let customFieldSection = section(withCategory: .customFields, from: dataSource)
        XCTAssertNil(customFieldSection)
    }
}

// MARK: - Test Data

private extension OrderDetailsDataSourceTests {
    func makeOrder() -> Order {
        MockOrders().makeOrder(items: [makeOrderItem(), makeOrderItem()])
    }

    func makeOrderItem() -> OrderItem {
        OrderItem(itemID: 1,
                  name: "Order Item Name",
                  productID: 100,
                  variationID: 0,
                  quantity: 1,
                  price: NSDecimalNumber(integerLiteral: 1),
                  sku: nil,
                  subtotal: "1",
                  subtotalTax: "1",
                  taxClass: "TaxClass",
                  taxes: [],
                  total: "1",
                  totalTax: "1",
                  attributes: [])
    }

    func makeRefund(orderID: Int64, siteID: Int64) -> Refund {
        let orderItemRefund = OrderItemRefund(itemID: 1,
                                              name: "OrderItemRefund",
                                              productID: 1,
                                              variationID: 1,
                                              refundedItemID: "1",
                                              quantity: 1,
                                              price: NSDecimalNumber(integerLiteral: 1),
                                              sku: nil,
                                              subtotal: "1",
                                              subtotalTax: "1",
                                              taxClass: "TaxClass",
                                              taxes: [],
                                              total: "1",
                                              totalTax: "1")
        return Refund(refundID: 1,
                      orderID: orderID,
                      siteID: siteID,
                      dateCreated: Date(),
                      amount: "1",
                      reason: "Reason",
                      refundedByUserID: 1,
                      isAutomated: nil,
                      createAutomated: nil,
                      items: [orderItemRefund],
                      shippingLines: [])
    }

    func insert(refund: Refund) {
        let storageOrderItemRefunds: Set<StorageOrderItemRefund> = Set(refund.items.map { orderItemRefund in
            let storageOrderItemRefund = storage.insertNewObject(ofType: StorageOrderItemRefund.self)
            storageOrderItemRefund.update(with: orderItemRefund)
            return storageOrderItemRefund
        })

        let storageRefund = storage.insertNewObject(ofType: StorageRefund.self)
        storageRefund.update(with: refund)
        storageRefund.addToItems(storageOrderItemRefunds as NSSet)
    }

    /// Inserts the shipping label into storage
    ///
    func insert(shippingLabel: ShippingLabel) {
        let storageShippingLabel = storage.insertNewObject(ofType: StorageShippingLabel.self)
        storageShippingLabel.update(with: shippingLabel)
        if let shippingLabelRefund = shippingLabel.refund {
            let storageRefund = storage.insertNewObject(ofType: StorageShippingLabelRefund.self)
            storageRefund.update(with: shippingLabelRefund)
            storageShippingLabel.refund = storageRefund
        }
    }

    func insert(_ readOnlyPlugin: Yosemite.SitePlugin) {
        let plugin = storage.insertNewObject(ofType: StorageSitePlugin.self)
        plugin.update(with: readOnlyPlugin)
        storage.saveIfNeeded()
    }

    /// Finds first section with a given title from the provided data source.
    ///
    private func section(withTitle title: String, from dataSource: OrderDetailsDataSource) throws -> OrderDetailsDataSource.Section {
        let section = dataSource.sections.first { $0.title == title }
        return try XCTUnwrap(section)
    }

    /// Finds first section with a given category from the provided data source.
    ///
    private func section(withCategory category: OrderDetailsDataSource.Section.Category,
                         from dataSource: OrderDetailsDataSource) -> OrderDetailsDataSource.Section? {
        let section = dataSource.sections.first { $0.category == category }
        return section
    }

    /// Finds the first row that matches the given row from the provided section.
    ///
    func row(row: OrderDetailsDataSource.Row, in section: OrderDetailsDataSource.Section) -> OrderDetailsDataSource.Row? {
        section.rows.first { $0 == row }
    }
}

private extension OrderDetailsDataSourceTests {
    enum Mocks {
        static let configuration = CardPresentPaymentsConfiguration(country: "US")
    }
}
