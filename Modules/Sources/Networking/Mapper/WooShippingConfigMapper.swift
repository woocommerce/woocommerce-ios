import Foundation

struct WooShippingConfigMapper: Mapper {
    /// Site Identifier associated to the order that will be parsed.
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because SiteID is not returned by the config endpoint.
    ///
    let siteID: Int64

    /// Order ID associated to the shipping labels that will be parsed.
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because OrderID is not returned by the config endpoint.
    ///
    let orderID: Int64

    /// (Attempts) to convert a dictionary into `WooShippingConfig`.
    ///
    func map(response: Data) throws -> WooShippingConfig {
        let decoder = JSONDecoder()
        decoder.userInfo = [
            .siteID: siteID,
            .orderID: orderID
        ]
        if hasDataEnvelope(in: response) {
            return try decoder.decode(WooShippingConfigMapperEnvelope.self, from: response).data.config
        } else {
            return try decoder.decode(WooShippingConfigResponse.self, from: response).config
        }
    }
}

/// WooShippingConfigMapperEnvelope Disposable Entity:
/// `Woo Shipping Config` endpoint returns the shipping label config in the `data` key.
/// This entity allows us to do parse all the things with JSONDecoder.
///
private struct WooShippingConfigMapperEnvelope: Decodable {
    let data: WooShippingConfigResponse

    private enum CodingKeys: String, CodingKey {
        case data = "data"
    }
}

extension WooShippingConfigMapper {
    /// Load only the relevant fields from remote
    ///
    static let fieldsToLoad = [
        "config.shipments",
        "config.shippingLabelData.currentOrderLabels",
        "config.shippingLabelData.storedData.selected_destination",
        "config.shippingLabelData.storedData.selected_origin",
        "config.shippingLabelData.storedData.selected_hazmat"
    ].joined(separator: ", ")
}
