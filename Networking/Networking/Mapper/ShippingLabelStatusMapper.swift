import Foundation

/// Mapper: Check Status of Shipping Labels
///
struct ShippingLabelStatusMapper: Mapper {
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

    /// (Attempts) to convert a dictionary into `ShippingLabelStatusPollingResponse`.
    ///
    func map(response: Data) throws -> [ShippingLabelStatusPollingResponse] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        decoder.userInfo = [
            .siteID: siteID,
            .orderID: orderID
        ]

        return try decoder.decode(ShippingLabelStatusResponse.self, from: response).data.labels
    }
}

/// ShippingLabelPurchaseResponse Disposable Entity
///
/// `Check Shipping Labels Status` endpoint returns the data wrapper in the `data` key.
///
private struct ShippingLabelStatusResponse: Decodable {
    let data: ShippingLabelStatusEnvelope

    private enum CodingKeys: String, CodingKey {
        case data
    }
}

/// ShippingLabelPurchaseEnvelope Disposable Entity
///
/// `Check Shipping Labels Status` endpoint returns the shipping label purchases in the `data.labels` key.
///
private struct ShippingLabelStatusEnvelope: Decodable {
    let labels: [ShippingLabelStatusPollingResponse]

    private enum CodingKeys: String, CodingKey {
        case labels
    }
}
