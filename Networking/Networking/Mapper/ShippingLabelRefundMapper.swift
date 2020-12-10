import Foundation


/// Mapper: Shipping Label Refund Mapper
///
struct ShippingLabelRefundMapper: Mapper {
    /// (Attempts) to convert a dictionary into ShippingLabelRefund.
    ///
    func map(response: Data) throws -> ShippingLabelRefund {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        return try decoder.decode(ShippingLabelRefundResponse.self, from: response).data.refund
    }
}

/// ShippingLabelRefundResponse Disposable Entity:
/// `Refund Shipping Label` endpoint returns the refund data wrapper in the `data` key.
/// This entity allows us to do parse all the things with JSONDecoder.
///
private struct ShippingLabelRefundResponse: Decodable {
    let data: ShippingLabelRefundEnvelope

    private enum CodingKeys: String, CodingKey {
        case data
    }
}

/// ShippingLabelRefundEnvelope Disposable Entity:
/// `Refund Shipping Label` endpoint returns the refund in the `data.refund` key.
/// This entity allows us to do parse all the things with JSONDecoder.
///
private struct ShippingLabelRefundEnvelope: Decodable {
    let refund: ShippingLabelRefund

    private enum CodingKeys: String, CodingKey {
        case refund
    }
}
