import Foundation

/// Mapper for an array of `PaymentGateway` JSON objects
///
struct PaymentGatewayListMapper: Mapper {

    /// Site Identifier associated to the shipment trackings that will be parsed.
    /// We're injecting this field via `JSONDecoder.userInfo` because the remote endpoints don't
    /// return the siteID for the payment gateway endpoint
    ///
    let siteID: Int64

    /// (Attempts) to convert a dictionary into `[PaymentGateway]`
    ///
    func map(response: Data) throws -> [PaymentGateway] {
        let decoder = JSONDecoder()
        decoder.userInfo = [
            .siteID: siteID,
        ]
        return try decoder.decode(PaymentGatewayListEnvelope.self, from: response).paymentGateways
    }
}

/// PaymentGateway list disposable entity:
/// `Load Payment Gateways` endpoint returns all of the gateway information within a `body` obejcts in the `data` key. This entity
/// allows us to parse all the things with JSONDecoder.
///
private struct PaymentGatewayListEnvelope: Decodable {
    private enum CodingKeys: String, CodingKey {
        case paymentGateways = "data"
    }

    let paymentGateways: [PaymentGateway]
}
