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

    func test_payment_section_is_shown_right_after_the_products_custom_amounts_refunded_products_and_shipping_sections() {
        // Given
        let order = makeOrder()

        insert(refund: makeRefund(refundID: 1, orderID: order.orderID, siteID: order.siteID))
        insertFee(with: order)

        let dataSource = OrderDetailsDataSource(
            order: order,
            storageManager: storageManager,
            cardPresentPaymentsConfiguration: Mocks.configuration
        )

        dataSource.configureResultsControllers { }

        // When
        dataSource.reloadSections()

        // Then
        let actualTitles = dataSource.sections.compactMap(\.title)
        let expectedTitles = [
            Title.products,
            Title.customAmounts,
            Title.refundedProducts,
            Title.shippingLines,
            Title.payment,
            Title.information,
            Title.orderAttribution,
            Title.notes
        ]

        XCTAssertEqual(actualTitles, expectedTitles)
    }

    func test_refunds_data_in_unpaid_order_is_acessible_by_indexes() throws {
        // Given
        let refundItems = [
            OrderRefundCondensed(refundID: 1, reason: nil, total: "1"),
            OrderRefundCondensed(refundID: 2, reason: nil, total: "1"),
        ]
        let order = makeOrder().copy(datePaid: .some(nil), refunds: refundItems)

        insert(refund: makeRefund(refundID: 1, orderID: order.orderID, siteID: order.siteID))
        insert(refund: makeRefund(refundID: 2, orderID: order.orderID, siteID: order.siteID))

        let dataSource = OrderDetailsDataSource(
            order: order,
            storageManager: storageManager,
            cardPresentPaymentsConfiguration: Mocks.configuration
        )

        dataSource.configureResultsControllers { }

        // Temp tableview to test refunds rows configuration
        let tableView = UITableView()
        tableView.registerNib(for: TwoColumnHeadlineFootnoteTableViewCell.self)

        // When
        dataSource.reloadSections()

        // Get IndexPaths for all `refund` rows
        var refundsRowsIndexes: [IndexPath] = []
        for (sectionIndex, section) in dataSource.sections.enumerated() {
            for (rowIndex, row) in section.rows.enumerated() where row == .refund {
                refundsRowsIndexes.append(IndexPath(row: rowIndex, section: sectionIndex))
            }
        }

        // Then
        // Each `refund` row should be initialized without any issues
        for refundIndexPath in refundsRowsIndexes {
            let _ = dataSource.tableView(tableView, cellForRowAt: refundIndexPath)
        }
        // Each `refund` row should have `Refund` object accessible for its IndexPath
        let expectedRefunds: [Refund] = try refundsRowsIndexes.map { try XCTUnwrap(dataSource.refund(at: $0)) }
        XCTAssertEqual(expectedRefunds.count, refundsRowsIndexes.count)
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
        let order = makeOrder().copy(datePaid: .some(nil)) // Unpaid orders are eligible for payment
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
        let order = makeOrder().copy(status: .processing, datePaid: .some(nil), total: "100")
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
        let activePlugin = SitePlugin.fake().copy(siteID: sampleSiteID, status: .active, name: SitePlugin.SupportedPlugin.LegacyWCShip)
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
                value: CountryCode.US.rawValue,
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
                value: CountryCode.US.rawValue,
                settingGroupKey: SiteSettingGroup.general.rawValue
            )

        let dataSource = OrderDetailsDataSource(order: order,
                                                storageManager: storageManager,
                                                cardPresentPaymentsConfiguration: CardPresentPaymentsConfiguration(country: .US),
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
        guard case .twoColumn = productSection.headerStyle else {
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
        guard case .twoColumn = productSection.headerStyle else {
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
        guard case .twoColumn = productSection.headerStyle else {
            XCTFail("Product section should not show button on the header for cash on delivery order")
            return
        }
    }

    func test_custom_fields_button_is_visible() throws {
        // Given
        let order = MockOrders().makeOrder(customFields: [
            MetaData(metadataID: 123, key: "Key", value: "Value")
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

    func test_subscriptions_section_is_visible_when_order_has_associated_subscriptions() throws {
        // Given
        let order = MockOrders().makeOrder()
        let dataSource = OrderDetailsDataSource(order: order,
                                                storageManager: storageManager,
                                                cardPresentPaymentsConfiguration: Mocks.configuration
        )

        // When
        dataSource.orderSubscriptions = [Subscription.fake()]

        // Then
        let subscriptionSection = section(withCategory: .subscriptions, from: dataSource)
        XCTAssertNotNil(subscriptionSection)
    }

    func test_subscriptions_section_is_hidden_when_order_has_no_associated_subscriptions() throws {
        // Given
        let order = MockOrders().makeOrder()
        let dataSource = OrderDetailsDataSource(order: order,
                                                storageManager: storageManager,
                                                cardPresentPaymentsConfiguration: Mocks.configuration
        )

        // When
        dataSource.orderSubscriptions = []

        // Then
        let subscriptionSection = section(withCategory: .subscriptions, from: dataSource)
        XCTAssertNil(subscriptionSection)
    }

    func test_reloadSections_when_order_has_custom_amounts_then_custom_amounts_section_is_visible() {
        // Given
        let order = MockOrders().makeOrder(fees: [OrderFeeLine.fake()])
        let dataSource = OrderDetailsDataSource(order: order,
                                                storageManager: storageManager,
                                                cardPresentPaymentsConfiguration: Mocks.configuration)

        // When
        insertFee(with: order)
        dataSource.configureResultsControllers { }
        dataSource.reloadSections()

        // Then
        let customAmountsSection = section(withCategory: .customAmounts, from: dataSource)
        XCTAssertNotNil(customAmountsSection)
    }

    func test_reloadSections_when_order_has_not_custom_amounts_then_custom_amounts_section_is_hidden() {
        // Given
        let order = MockOrders().makeOrder(fees: [])
        let dataSource = OrderDetailsDataSource(order: order,
                                                storageManager: storageManager,
                                                cardPresentPaymentsConfiguration: Mocks.configuration)

        // When
        dataSource.reloadSections()

        // Then
        let customAmountsSection = section(withCategory: .customAmounts, from: dataSource)
        XCTAssertNil(customAmountsSection)
    }

    func test_giftCards_section_is_visible_when_order_has_gift_cards() throws {
        // Given
        let order = Order.fake().copy(appliedGiftCards: [.init(giftCardID: 2, code: "SU9F-MGB5-KS5V-EZFT", amount: 20)])
        let dataSource = OrderDetailsDataSource(order: order,
                                                storageManager: storageManager,
                                                cardPresentPaymentsConfiguration: Mocks.configuration)

        // When
        dataSource.reloadSections()

        // Then
        let giftCardsSection = section(withCategory: .giftCards, from: dataSource)
        XCTAssertNotNil(giftCardsSection)
    }

    func test_giftCards_section_is_hidden_when_order_has_no_gift_cards() throws {
        // Given
        let order = Order.fake()
        let dataSource = OrderDetailsDataSource(order: order,
                                                storageManager: storageManager,
                                                cardPresentPaymentsConfiguration: Mocks.configuration)

        // When
        dataSource.reloadSections()

        // Then
        let giftCardsSection = section(withCategory: .giftCards, from: dataSource)
        XCTAssertNil(giftCardsSection)
    }

    func test_receipts_row_is_hidden_when_feature_flag_is_false() throws {
        // Given
        let order = Order.fake()
        let dataSource = OrderDetailsDataSource(order: order,
                                                storageManager: storageManager,
                                                cardPresentPaymentsConfiguration: Mocks.configuration,
                                                featureFlags: MockFeatureFlagService(isBackendReceiptsEnabled: false))

        // When
        dataSource.reloadSections()

        // Then
        let paymentSection = try section(withTitle: Title.payment, from: dataSource)
        let receiptsRow = row(row: .seeReceipt, in: paymentSection)
        XCTAssertNil(receiptsRow)
    }

    // MARK: Order Attribution

    func test_order_attribution_section_is_shown_with_origin_row_even_if_order_has_no_attribution_info() throws {
        // Given
        let order = Order.fake().copy(attributionInfo: .some(nil))
        let dataSource = OrderDetailsDataSource(order: order,
                                                storageManager: storageManager,
                                                cardPresentPaymentsConfiguration: Mocks.configuration)

        // When
        dataSource.reloadSections()

        // Then
        let attributionSection = try section(withTitle: Title.orderAttribution, from: dataSource)
        let originRow = row(row: .attributionOrigin, in: attributionSection)
        XCTAssertNotNil(originRow)
    }

    func test_order_attribution_section_hides_source_type_row_when_sourceType_is_nil() throws {
        // Given
        let order = Order.fake().copy(attributionInfo: .fake().copy(sourceType: .some(nil)))
        let dataSource = OrderDetailsDataSource(order: order, storageManager: storageManager, cardPresentPaymentsConfiguration: Mocks.configuration)

        // When
        dataSource.reloadSections()

        // Then
        let attributionSection = try section(withTitle: Title.orderAttribution, from: dataSource)
        let row = row(row: .attributionSourceType, in: attributionSection)
        XCTAssertNil(row)
    }

    func test_order_attribution_section_shows_source_type_row_when_sourceType_is_not_nil() throws {
        // Given
        let order = Order.fake().copy(attributionInfo: .fake().copy(sourceType: "Source type"))
        let dataSource = OrderDetailsDataSource(order: order, storageManager: storageManager, cardPresentPaymentsConfiguration: Mocks.configuration)

        // When
        dataSource.reloadSections()

        // Then
        let attributionSection = try section(withTitle: Title.orderAttribution, from: dataSource)
        let row = row(row: .attributionSourceType, in: attributionSection)
        XCTAssertNotNil(row)
    }

    func test_order_attribution_section_hides_campaign_row_when_campaign_is_nil() throws {
        // Given
        let order = Order.fake().copy(attributionInfo: .fake().copy(campaign: .some(nil)))
        let dataSource = OrderDetailsDataSource(order: order, storageManager: storageManager, cardPresentPaymentsConfiguration: Mocks.configuration)

        // When
        dataSource.reloadSections()

        // Then
        let attributionSection = try section(withTitle: Title.orderAttribution, from: dataSource)
        let row = row(row: .attributionCampaign, in: attributionSection)
        XCTAssertNil(row)
    }

    func test_order_attribution_section_shows_campaign_row_when_campaign_is_not_nil() throws {
        // Given
        let order = Order.fake().copy(attributionInfo: .fake().copy(campaign: "Campaign"))
        let dataSource = OrderDetailsDataSource(order: order, storageManager: storageManager, cardPresentPaymentsConfiguration: Mocks.configuration)

        // When
        dataSource.reloadSections()

        // Then
        let attributionSection = try section(withTitle: Title.orderAttribution, from: dataSource)
        let row = row(row: .attributionCampaign, in: attributionSection)
        XCTAssertNotNil(row)
    }

    func test_order_attribution_section_hides_source_row_when_source_is_nil() throws {
        // Given
        let order = Order.fake().copy(attributionInfo: .fake().copy(source: .some(nil)))
        let dataSource = OrderDetailsDataSource(order: order, storageManager: storageManager, cardPresentPaymentsConfiguration: Mocks.configuration)

        // When
        dataSource.reloadSections()

        // Then
        let attributionSection = try section(withTitle: Title.orderAttribution, from: dataSource)
        let row = row(row: .attributionSource, in: attributionSection)
        XCTAssertNil(row)
    }

    func test_order_attribution_section_shows_source_row_when_source_is_not_nil() throws {
        // Given
        let order = Order.fake().copy(attributionInfo: .fake().copy(source: "Source"))
        let dataSource = OrderDetailsDataSource(order: order, storageManager: storageManager, cardPresentPaymentsConfiguration: Mocks.configuration)

        // When
        dataSource.reloadSections()

        // Then
        let attributionSection = try section(withTitle: Title.orderAttribution, from: dataSource)
        let row = row(row: .attributionSource, in: attributionSection)
        XCTAssertNotNil(row)
    }

    func test_order_attribution_section_hides_medium_row_when_medium_is_nil() throws {
        // Given
        let order = Order.fake().copy(attributionInfo: .fake().copy(medium: .some(nil)))
        let dataSource = OrderDetailsDataSource(order: order, storageManager: storageManager, cardPresentPaymentsConfiguration: Mocks.configuration)

        // When
        dataSource.reloadSections()

        // Then
        let attributionSection = try section(withTitle: Title.orderAttribution, from: dataSource)
        let row = row(row: .attributionMedium, in: attributionSection)
        XCTAssertNil(row)
    }

    func test_order_attribution_section_shows_medium_row_when_medium_is_not_nil() throws {
        // Given
        let order = Order.fake().copy(attributionInfo: .fake().copy(medium: "Medium"))
        let dataSource = OrderDetailsDataSource(order: order, storageManager: storageManager, cardPresentPaymentsConfiguration: Mocks.configuration)

        // When
        dataSource.reloadSections()

        // Then
        let attributionSection = try section(withTitle: Title.orderAttribution, from: dataSource)
        let row = row(row: .attributionMedium, in: attributionSection)
        XCTAssertNotNil(row)
    }

    func test_order_attribution_section_hides_deviceType_row_when_deviceType_is_nil() throws {
        // Given
        let order = Order.fake().copy(attributionInfo: .fake().copy(deviceType: .some(nil)))
        let dataSource = OrderDetailsDataSource(order: order, storageManager: storageManager, cardPresentPaymentsConfiguration: Mocks.configuration)

        // When
        dataSource.reloadSections()

        // Then
        let attributionSection = try section(withTitle: Title.orderAttribution, from: dataSource)
        let row = row(row: .attributionDeviceType, in: attributionSection)
        XCTAssertNil(row)
    }

    func test_order_attribution_section_shows_deviceType_row_when_deviceType_is_not_nil() throws {
        // Given
        let order = Order.fake().copy(attributionInfo: .fake().copy(deviceType: "Device type"))
        let dataSource = OrderDetailsDataSource(order: order, storageManager: storageManager, cardPresentPaymentsConfiguration: Mocks.configuration)

        // When
        dataSource.reloadSections()

        // Then
        let attributionSection = try section(withTitle: Title.orderAttribution, from: dataSource)
        let row = row(row: .attributionDeviceType, in: attributionSection)
        XCTAssertNotNil(row)
    }

    func test_order_attribution_section_hides_sessionPageViews_row_when_sessionPageViews_is_nil() throws {
        // Given
        let order = Order.fake().copy(attributionInfo: .fake().copy(sessionPageViews: .some(nil)))
        let dataSource = OrderDetailsDataSource(order: order, storageManager: storageManager, cardPresentPaymentsConfiguration: Mocks.configuration)

        // When
        dataSource.reloadSections()

        // Then
        let attributionSection = try section(withTitle: Title.orderAttribution, from: dataSource)
        let row = row(row: .attributionSessionPageViews, in: attributionSection)
        XCTAssertNil(row)
    }

    func test_order_attribution_section_shows_sessionPageViews_row_when_sessionPageViews_is_not_nil() throws {
        // Given
        let order = Order.fake().copy(attributionInfo: .fake().copy(sessionPageViews: "3"))
        let dataSource = OrderDetailsDataSource(order: order, storageManager: storageManager, cardPresentPaymentsConfiguration: Mocks.configuration)

        // When
        dataSource.reloadSections()

        // Then
        let attributionSection = try section(withTitle: Title.orderAttribution, from: dataSource)
        let row = row(row: .attributionSessionPageViews, in: attributionSection)
        XCTAssertNotNil(row)
    }

    func test_shipping_section_hidden_when_order_has_no_shipping_lines() {
        // Given
        let order = Order.fake()
        let dataSource = OrderDetailsDataSource(order: order, storageManager: storageManager, cardPresentPaymentsConfiguration: Mocks.configuration)

        // When
        dataSource.reloadSections()

        // Then
        let shippingSection = section(withCategory: .shippingLines, from: dataSource)
        XCTAssertNil(shippingSection)
    }

    func test_shipping_section_shows_shipping_line_row_when_order_has_shipping_line() throws {
        // Given
        let order = Order.fake().copy(shippingLines: [.fake()])
        let dataSource = OrderDetailsDataSource(order: order,
                                                storageManager: storageManager,
                                                cardPresentPaymentsConfiguration: Mocks.configuration)

        // When
        dataSource.reloadSections()

        // Then
        let shippingSection = try section(withTitle: Title.shippingLines, from: dataSource)
        let row = row(row: .shippingLine, in: shippingSection)
        XCTAssertNotNil(row)
    }
}

// MARK: - Test Data

private extension OrderDetailsDataSourceTests {
    func makeOrder() -> Order {
        MockOrders().makeOrder(items: [makeOrderItem(), makeOrderItem()], fees: [OrderFeeLine.fake()])
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
                  attributes: [],
                  addOns: [],
                  parent: nil,
                  bundleConfiguration: [])
    }

    func makeRefund(refundID: Int64, orderID: Int64, siteID: Int64) -> Refund {
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
        return Refund(refundID: refundID,
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

    func insertFee(with order: Order) {
        let storageOrder = storage.insertNewObject(ofType: StorageOrder.self)
        storageOrder.update(with: order)
        let storageFee = storage.insertNewObject(ofType: StorageOrderFeeLine.self)
        storageFee.order = storageOrder
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
        static let configuration = CardPresentPaymentsConfiguration(country: .US)
    }
}
