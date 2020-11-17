import Foundation

/// Represents a Shipping Label Refund.
///
public struct ShippingLabelRefund: Equatable {
    /// The date of refund request.
    public let dateRequested: Date

    /// The status of the refund (e.g. pending).
    public let status: ShippingLabelRefundStatus
}

// MARK: Decodable
extension ShippingLabelRefund: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let dateRequestedTimestamp = try container.decode(Int64.self, forKey: .dateRequested)
        let dateRequested = Date(timeIntervalSince1970: TimeInterval(dateRequestedTimestamp/1000))

        let statusRawValue = try container.decode(String.self, forKey: .status)
        let status = ShippingLabelRefundStatus(rawValue: statusRawValue)

        self.init(dateRequested: dateRequested, status: status)
    }

    private enum CodingKeys: String, CodingKey {
        case dateRequested = "request_date"
        case status
    }
}
