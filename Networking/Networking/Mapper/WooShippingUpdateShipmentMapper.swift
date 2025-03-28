import Foundation

/// Mapper: Shipping Label Update Shipments Response from WooCommerce Shipping extension
///
struct WooShippingUpdateShipmentMapper: Mapper {
    /// Site Identifier associated to the order that will be parsed.
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because SiteID is not returned by the update shipment endpoint.
    ///
    let siteID: Int64

    /// Order ID associated to the shipping labels that will be parsed.
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because OrderID is not returned by the update shipment endpoint.
    ///
    let orderID: Int64

    /// (Attempts) to convert a dictionary into WooShippingUpdateShipmentResponse.
    ///
    func map(response: Data) throws -> WooShippingUpdateShipmentResponse {
        let decoder = JSONDecoder()
        decoder.userInfo = [
            .siteID: siteID,
            .orderID: orderID
        ]
        if hasDataEnvelope(in: response) {
            return try decoder.decode(WooShippingUpdateShipmentResponseEnvelope.self, from: response).data
        } else {
            return try decoder.decode(WooShippingUpdateShipmentResponse.self, from: response)
        }
    }
}

private struct WooShippingUpdateShipmentResponseEnvelope: Decodable {
    let data: WooShippingUpdateShipmentResponse

    private enum CodingKeys: String, CodingKey {
        case data = "data"
    }
}
