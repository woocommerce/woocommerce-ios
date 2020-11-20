import Foundation

/// Represents a Shipping Label Refund.
///
public struct ShippingLabelRefund: Equatable {
    /// The date of refund request.
    public let dateRequested: Date

    /// The status of the refund (e.g. pending).
    public let status: ShippingLabelRefundStatus

    public init(dateRequested: Date, status: ShippingLabelRefundStatus) {
        self.dateRequested = dateRequested
        self.status = status
    }
}

// MARK: Decodable
extension ShippingLabelRefund: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let dateRequested = try container.decode(Date.self, forKey: .dateRequested)

        let statusRawValue = try container.decode(String.self, forKey: .status)
        let status = ShippingLabelRefundStatus(rawValue: statusRawValue)

        self.init(dateRequested: dateRequested, status: status)
    }

    private enum CodingKeys: String, CodingKey {
        case dateRequested = "request_date"
        case status
    }
}
