/// Mapper: Shipping Label Refund Mapper
///
struct ShippingLabelRefundMapper: Mapper {
    /// (Attempts) to convert a dictionary into ShippingLabelRefund.
    ///
    func map(response: Data) throws -> ShippingLabelRefund {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        if hasDataEnvelope(in: response) {
            return try decoder.decode(Envelope<ShippingLabelRefundEnvelope>.self, from: response).data.refund
        } else {
            return try decoder.decode(ShippingLabelRefundEnvelope.self, from: response).refund
        }
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
