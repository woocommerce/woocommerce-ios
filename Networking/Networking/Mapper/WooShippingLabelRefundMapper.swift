import Foundation


/// Mapper for refund result from Woo Shipping plugin
///
struct WooShippingLabelRefundMapper: Mapper {
    /// Site Identifier associated to the label that will be parsed.
    /// We're injecting this field via `JSONDecoder.userInfo` because the remote endpoints don't return the SiteID.
    ///
    let siteID: Int64

    /// Order Identifier associated to the label that will be parsed.
    /// We're injecting this field via `JSONDecoder.userInfo` because the remote endpoints don't return the SiteID.
    ///
    let orderID: Int64


    /// (Attempts) to convert a dictionary into ShippingLabel.
    ///
    func map(response: Data) throws -> ShippingLabel {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        decoder.userInfo = [
            .siteID: siteID,
            .orderID: orderID
        ]

        if hasDataEnvelope(in: response) {
            return try decoder.decode(WooShippingLabelRefundResponse.self, from: response).data.label
        } else {
            return try decoder.decode(WooShippingLabelRefundEnvelope.self, from: response).label
        }
    }
}

/// WooShippingLabelRefundResponse Disposable Entity:
/// `Woo Shipping Refund Label` endpoint returns the shipping label data wrapper in the `data` key.
/// This entity allows us to do parse all the things with JSONDecoder.
///
private struct WooShippingLabelRefundResponse: Decodable {
    let data: WooShippingLabelRefundEnvelope

    private enum CodingKeys: String, CodingKey {
        case data
    }
}

/// WooShippingLabelRefundEnvelope Disposable Entity:
/// `Woo Shipping Refund Label` endpoint returns the updated label in the `data.label` key.
/// This entity allows us to do parse all the things with JSONDecoder.
///
private struct WooShippingLabelRefundEnvelope: Decodable {
    let label: ShippingLabel

    private enum CodingKeys: String, CodingKey {
        case label
    }
}
