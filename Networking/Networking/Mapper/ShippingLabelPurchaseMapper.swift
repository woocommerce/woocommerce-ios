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

        return try decoder.decode(ShippingLabelPurchaseResponse.self, from: response).data.labels
    }
}

/// ShippingLabelPurchaseResponse Disposable Entity
///
/// `Purchase Shipping Labels` endpoint returns the data wrapper in the `data` key.
///
private struct ShippingLabelPurchaseResponse: Decodable {
    let data: ShippingLabelPurchaseEnvelope

    private enum CodingKeys: String, CodingKey {
        case data
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
