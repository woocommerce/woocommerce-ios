import Codegen
import Foundation

/// Blaze billing summary of the current WPCom user.
public struct BlazeBillingSummary: Decodable, Equatable, GeneratedFakeable, GeneratedCopiable {

    /// Amount the user failed to pay for previous campaigns, in USD.
    public let debt: Double

    /// Unpaid orders that the user can pay to clear the debt.
    public let paymentLinks: [PaymentLink]

    public init(debt: Double, paymentLinks: [PaymentLink]) {
        self.debt = debt
        self.paymentLinks = paymentLinks
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        debt = container.failsafeDecodeIfPresent(targetType: Double.self,
                                                 forKey: .debt,
                                                 alternativeTypes: [.string(transform: { Double($0) ?? 0 })]) ?? 0
        paymentLinks = try container.decodeIfPresent([PaymentLink].self, forKey: .paymentLinks) ?? []
    }

    private enum CodingKeys: String, CodingKey {
        case debt
        case paymentLinks
    }
}

public extension BlazeBillingSummary {

    /// Unpaid order with a link to pay it.
    struct PaymentLink: Decodable, Equatable, GeneratedFakeable, GeneratedCopiable {

        /// Creation date of the order.
        public let date: Date?

        /// Amount of the order, in USD.
        public let amount: Double

        /// Link to pay the order.
        public let url: String

        public init(date: Date?, amount: Double, url: String) {
            self.date = date
            self.amount = amount
            self.url = url
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            date = try container.decodeIfPresent(String.self, forKey: .date).flatMap(dateFormatter.date(from:))
            amount = container.failsafeDecodeIfPresent(targetType: Double.self,
                                                       forKey: .amount,
                                                       alternativeTypes: [.string(transform: { Double($0) ?? 0 })]) ?? 0
            url = try container.decode(String.self, forKey: .url)
        }

        private enum CodingKeys: String, CodingKey {
            case date
            case amount
            case url
        }
    }
}
