import Foundation

/// Mapper: Shipping Label Update Shipments Response from WooCommerce Shipping extension
///
struct WooShippingUpdateShipmentMapper: Mapper {
    /// (Attempts) to convert a dictionary into a dictionary of `WooShippingShipment` values.
    ///
    func map(response: Data) throws -> WooShippingShipments {
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(WooShippingUpdateShipmentResponseEnvelope.self, from: response).data.shipments
        } catch {
            return try decoder.decode(WooShippingUpdateShipmentResponse.self, from: response).shipments
        }
    }
}

private struct WooShippingUpdateShipmentResponseEnvelope: Decodable {
    let data: WooShippingUpdateShipmentResponse

    private enum CodingKeys: String, CodingKey {
        case data = "data"
    }
}
