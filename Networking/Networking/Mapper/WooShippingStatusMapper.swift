import Foundation

/// Mapper: Check Status of Shipping Labels in Woo Shipping extension
///
struct WooShippingStatusMapper: Mapper {
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
    func map(response: Data) throws -> ShippingLabelStatusPollingResponse {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        decoder.userInfo = [
            .siteID: siteID,
            .orderID: orderID
        ]

        if hasDataEnvelope(in: response) {
            return try decoder.decode(WooShippingStatusResponse.self, from: response).data.label
        } else {
            return try decoder.decode(WooShippingStatusEnvelope.self, from: response).label
        }
    }
}

/// WooShippingStatusResponse Disposable Entity
///
/// `Check Label Status` endpoint returns the data wrapper in the `data` key.
///
private struct WooShippingStatusResponse: Decodable {
    let data: WooShippingStatusEnvelope

    private enum CodingKeys: String, CodingKey {
        case data
    }
}

/// WooShippingStatusEnvelope Disposable Entity
///
/// `Check Label Status` endpoint returns the shipping label purchase in the `data.label` key.
///
private struct WooShippingStatusEnvelope: Decodable {
    let label: ShippingLabelStatusPollingResponse

    private enum CodingKeys: String, CodingKey {
        case label
    }
}
