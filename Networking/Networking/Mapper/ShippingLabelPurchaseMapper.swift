import Foundation

/// Mapper: List of Shipping Label Purchases
///
struct ShippingLabelPurchaseMapper: Mapper {
    /// Site ID associated to the shipping labels that will be parsed.
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because SiteID is not returned in any of the shipping label endpoints.
    ///
    let siteID: Int64

    /// Order ID associated to the shipping labels that will be parsed.
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because OrderID is not returned in any of the shipping label endpoints.
    ///
    let orderID: Int64

    /// (Attempts) to convert a dictionary into [ShippingLabelPurchase].
    ///
    func map(response: Data) throws -> [ShippingLabelPurchase] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        decoder.userInfo = [
            .siteID: siteID,
            .orderID: orderID
        ]

        let container: ShippingLabelPurchaseEnvelope
        if hasDataEnvelope(in: response) {
            container = try decoder.decode(Envelope<ShippingLabelPurchaseEnvelope>.self, from: response).data
        } else {
            container = try decoder.decode(ShippingLabelPurchaseEnvelope.self, from: response)
        }

        return container.labels
    }
}

/// ShippingLabelPurchaseEnvelope Disposable Entity
///
/// `Purchase Shipping Labels` endpoint returns the shipping label purchases in the `data.labels` key.
///
private struct ShippingLabelPurchaseEnvelope: Decodable {
    let labels: [ShippingLabelPurchase]

    private enum CodingKeys: String, CodingKey {
        case labels
    }
}
