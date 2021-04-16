import XCTest
@testable import WooCommerce
import Yosemite

final class ProductDetailsCellViewModelTests: XCTestCase {
    private let currencyFormatter = CurrencyFormatter(currencySettings: .init())

    // MARK: `OrderItem`

    func test_initializing_with_OrderItem() {
        // Given
        let sku = "sku"
        let item = makeOrderItem(quantity: 2.5,
                                 price: 3.5,
                                 total: "8.5",
                                 sku: "sku",
                                 attributes: [])

        // When
        let viewModel = ProductDetailsCellViewModel(item: item,
                                                    currency: "$",
                                                    formatter: currencyFormatter,
                                                    hasAddOns: false)

        // Then
        XCTAssertEqual(viewModel.imageURL, nil)
        XCTAssertEqual(viewModel.name, item.name)
        let quantity = NumberFormatter.localizedString(from: item.quantity as NSDecimalNumber, number: .decimal)
        XCTAssertEqual(viewModel.quantity, quantity)
        XCTAssertEqual(viewModel.total, "$8.50")
        let subtitle = String.localizedStringWithFormat(Localization.subtitleFormat, quantity, "$3.50")
        XCTAssertEqual(viewModel.subtitle, subtitle)
        XCTAssertEqual(viewModel.sku, String.localizedStringWithFormat(Localization.skuFormat, sku))
    }

    // MARK: `AggregateOrderItem`

    func test_initializing_with_AggregateOrderItem() {
        // Given
        let sku = "sku"
        let item = makeAggregateOrderItem(quantity: 2,
                                          price: 3.5,
                                          total: 7,
                                          sku: sku,
                                          imageURL: URL(string: "woo.com/woo.jpeg"),
                                          attributes: [
                                            .init(metaID: 2, name: "Woo", value: "Wao"),
                                            .init(metaID: 25, name: "Wooo", value: "Waoo")
                                          ])


        // When
        let viewModel = ProductDetailsCellViewModel(aggregateItem: item,
                                                    currency: "$",
                                                    formatter: currencyFormatter,
                                                    hasAddOns: false)

        // Then
        XCTAssertEqual(viewModel.imageURL, item.imageURL)
        XCTAssertEqual(viewModel.name, item.name)
        let quantity = NumberFormatter.localizedString(from: item.quantity as NSDecimalNumber, number: .decimal)
        XCTAssertEqual(viewModel.quantity, quantity)
        XCTAssertEqual(viewModel.total, "$7.00")
        let subtitle = String.localizedStringWithFormat(Localization.subtitleWithAttributesFormat, "Wao, Waoo", quantity, "$3.50")
        XCTAssertEqual(viewModel.subtitle, subtitle)
        XCTAssertEqual(viewModel.sku, String.localizedStringWithFormat(Localization.skuFormat, sku))
    }

    func test_total_and_subtitle_are_empty_if_price_and_total_are_nil() {
        // Given
        let item = makeAggregateOrderItem(quantity: 2.5, price: nil, total: nil)

        // When
        let viewModel = ProductDetailsCellViewModel(aggregateItem: item, currency: "$",
                                                    hasAddOns: false)
        let total = viewModel.total
        let subtitle = viewModel.subtitle

        // Then
        XCTAssertEqual(total, "")
        XCTAssertEqual(subtitle, "")
    }

    func test_total_and_subtitle_are_not_empty_if_price_and_total_are_not_nil() {
        // Given
        let item = makeAggregateOrderItem(quantity: 2.5, price: 0.0, total: 0.0)

        // When
        let viewModel = ProductDetailsCellViewModel(aggregateItem: item, currency: "$",
                                                    hasAddOns: false)
        let total = viewModel.total
        let subtitle = viewModel.subtitle

        // Then
        XCTAssertNotEqual(total, "")
        XCTAssertNotEqual(subtitle, "")
    }

    // MARK: `OrderItemRefund`

    func test_initializing_with_OrderItemRefund_with_empty_sku() {
        // Given
        let item = makeOrderItemRefund(quantity: 2.5,
                                       price: -18,
                                       total: "-18",
                                       sku: "")

        // When
        let viewModel = ProductDetailsCellViewModel(refundedItem: item,
                                                    currency: "$",
                                                    formatter: currencyFormatter)

        // Then
        XCTAssertEqual(viewModel.imageURL, nil)
        XCTAssertEqual(viewModel.name, item.name)
        let quantity = NumberFormatter.localizedString(from: item.quantity as NSDecimalNumber, number: .decimal)
        XCTAssertEqual(viewModel.quantity, quantity)
        XCTAssertEqual(viewModel.total, "$18.00")
        let subtitle = String.localizedStringWithFormat(Localization.subtitleFormat, quantity, "$18.00")
        XCTAssertEqual(viewModel.subtitle, subtitle)
        XCTAssertEqual(viewModel.sku, nil)
    }
}

private extension ProductDetailsCellViewModelTests {
    func makeOrderItem(quantity: Decimal,
                       price: NSDecimalNumber,
                       total: String,
                       sku: String = "",
                       attributes: [OrderItemAttribute] = []) -> OrderItem {
        OrderItem(itemID: 0,
                  name: "fun order",
                  productID: 1,
                  variationID: 2,
                  quantity: quantity,
                  price: price,
                  sku: sku,
                  subtotal: "0",
                  subtotalTax: "1.0",
                  taxClass: "",
                  taxes: [],
                  total: total,
                  totalTax: "",
                  attributes: attributes)
    }

    func makeAggregateOrderItem(quantity: Decimal,
                                price: NSDecimalNumber?,
                                total: NSDecimalNumber?,
                                sku: String = "",
                                imageURL: URL? = nil,
                                attributes: [OrderItemAttribute] = []) -> AggregateOrderItem {
        AggregateOrderItem(productID: 1,
                           variationID: 6,
                           name: "order",
                           price: price,
                           quantity: quantity,
                           sku: sku,
                           total: total,
                           imageURL: imageURL,
                           attributes: attributes)
    }

    func makeOrderItemRefund(quantity: Decimal,
                             price: NSDecimalNumber,
                             total: String,
                             sku: String = "") -> OrderItemRefund {
        OrderItemRefund(itemID: 73,
                        name: "Ninja Silhouette",
                        productID: 1,
                        variationID: 6,
                        quantity: quantity,
                        price: price,
                        sku: sku,
                        subtotal: "-18.00",
                        subtotalTax: "0.00",
                        taxClass: "",
                        taxes: [],
                        total: total,
                        totalTax: "0.00")
    }
}

private extension ProductDetailsCellViewModelTests {
    enum Localization {
        static let skuFormat = NSLocalizedString("SKU: %1$@", comment: "SKU label in order details > product row. The variable shows the SKU of the product.")
        static let subtitleFormat =
            NSLocalizedString("%1$@ x %2$@", comment: "In Order Details,"
                                + " the pattern used to show the quantity multiplied by the price. For example, “23 x $400.00”."
                                + " The %1$@ is the quantity. The %2$@ is the formatted price with currency (e.g. $400.00).")
        static let subtitleWithAttributesFormat =
            NSLocalizedString("%1$@・%2$@ x %3$@", comment: "In Order Details > product details: if the product has attributes,"
                                + " the pattern used to show the attributes and quantity multiplied by the price. For example, “purple, has logo・23 x $400.00”."
                                + " The %1$@ is the list of attributes (e.g. from variation)."
                                + " The %2$@ is the quantity. The %3$@ is the formatted price with currency (e.g. $400.00).")
    }
}
