import Foundation
import Codegen

/// Server-calculated refund breakdown returned by `POST /wc/v4/refunds/preview`.
///
/// The preview is transient — it is never persisted. All monetary values arrive from the API as
/// strings (possibly null); decoding is lenient, mapping null/missing values to zero and null
/// sections to empty ones.
///
public struct RefundPreview: Decodable, Equatable, GeneratedFakeable {
    public let subtotal: Decimal
    public let tax: Decimal
    public let total: Decimal

    /// The maximum amount that can still be refunded on the order.
    public let maxRefundable: Decimal

    public let breakdown: Breakdown

    public init(subtotal: Decimal, tax: Decimal, total: Decimal, maxRefundable: Decimal, breakdown: Breakdown) {
        self.subtotal = subtotal
        self.tax = tax
        self.total = total
        self.maxRefundable = maxRefundable
        self.breakdown = breakdown
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(subtotal: container.decimalFromMoneyString(forKey: .subtotal),
                  tax: container.decimalFromMoneyString(forKey: .tax),
                  total: container.decimalFromMoneyString(forKey: .total),
                  maxRefundable: container.decimalFromMoneyString(forKey: .maxRefundable),
                  breakdown: (try? container.decodeIfPresent(Breakdown.self, forKey: .breakdown)) ?? .empty)
    }

    private enum CodingKeys: String, CodingKey {
        case subtotal
        case tax
        case total
        case maxRefundable = "max_refundable"
        case breakdown
    }
}

public extension RefundPreview {
    /// Per-type breakdown of the previewed refund.
    struct Breakdown: Decodable, Equatable, GeneratedFakeable {
        public let products: Section
        public let shipping: Section
        public let fees: Section

        static let empty = Breakdown(products: .empty, shipping: .empty, fees: .empty)

        public init(products: Section, shipping: Section, fees: Section) {
            self.products = products
            self.shipping = shipping
            self.fees = fees
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.init(products: (try? container.decodeIfPresent(Section.self, forKey: .products)) ?? .empty,
                      shipping: (try? container.decodeIfPresent(Section.self, forKey: .shipping)) ?? .empty,
                      fees: (try? container.decodeIfPresent(Section.self, forKey: .fees)) ?? .empty)
        }

        private enum CodingKeys: String, CodingKey {
            case products
            case shipping
            case fees
        }
    }

    /// One breakdown section (products, shipping, or fees) with its refunded lines and totals.
    struct Section: Decodable, Equatable, GeneratedFakeable {
        public let items: [Item]
        public let subtotal: Decimal
        public let tax: Decimal
        public let total: Decimal

        static let empty = Section(items: [], subtotal: .zero, tax: .zero, total: .zero)

        public init(items: [Item], subtotal: Decimal, tax: Decimal, total: Decimal) {
            self.items = items
            self.subtotal = subtotal
            self.tax = tax
            self.total = total
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.init(items: (try? container.decodeIfPresent([Item].self, forKey: .items)) ?? [],
                      subtotal: container.decimalFromMoneyString(forKey: .subtotal),
                      tax: container.decimalFromMoneyString(forKey: .tax),
                      total: container.decimalFromMoneyString(forKey: .total))
        }

        private enum CodingKeys: String, CodingKey {
            case items
            case subtotal
            case tax
            case total
        }
    }

    /// One previewed refund line.
    struct Item: Decodable, Equatable, GeneratedFakeable {
        public let id: Int64
        public let name: String

        /// Quantity being refunded. Nil for amount-based lines (fees/shipping).
        public let quantity: Decimal?

        public let subtotal: Decimal
        public let tax: Decimal
        public let total: Decimal

        /// Nil for lines that aren't products (fees/shipping).
        public let productID: Int64?

        public init(id: Int64, name: String, quantity: Decimal?, subtotal: Decimal, tax: Decimal, total: Decimal, productID: Int64?) {
            self.id = id
            self.name = name
            self.quantity = quantity
            self.subtotal = subtotal
            self.tax = tax
            self.total = total
            self.productID = productID
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.init(id: try container.decode(Int64.self, forKey: .id),
                      name: (try? container.decodeIfPresent(String.self, forKey: .name)) ?? "",
                      quantity: try? container.decodeIfPresent(Decimal.self, forKey: .quantity),
                      subtotal: container.decimalFromMoneyString(forKey: .subtotal),
                      tax: container.decimalFromMoneyString(forKey: .tax),
                      total: container.decimalFromMoneyString(forKey: .total),
                      productID: try? container.decodeIfPresent(Int64.self, forKey: .productID))
        }

        private enum CodingKeys: String, CodingKey {
            case id
            case name
            case quantity
            case subtotal
            case tax
            case total
            case productID = "product_id"
        }
    }
}

private extension KeyedDecodingContainer {
    /// Decodes an API money value that arrives as a string; null, missing, or unparseable values become zero.
    func decimalFromMoneyString(forKey key: Key) -> Decimal {
        guard let string = try? decodeIfPresent(String.self, forKey: key) else {
            return .zero
        }
        return Decimal(string: string) ?? .zero
    }
}
