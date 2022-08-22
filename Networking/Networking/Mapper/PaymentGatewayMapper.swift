import Foundation

/// Mapper for a `PaymentGateway` JSON object
///
struct PaymentGatewayMapper: Mapper {

    /// Site Identifier associated to the payment gateway that will be parsed.
    /// We're injecting this field via `JSONDecoder.userInfo` because the remote endpoints don't
    /// return the siteID for the payment gateway endpoint
    ///
    let siteID: Int64

    /// (Attempts) to convert a dictionary into `PaymentGateway`
    ///
    func map(response: Data) throws -> PaymentGateway {
        let decoder = JSONDecoder()
        decoder.userInfo = [
            .siteID: siteID,
        ]
        return try decoder.decode(PaymentGatewayEnvelope.self, from: response).paymentGateway
    }
}

/// PaymentGateway list disposable entity:
/// `Load Payment Gateway` endpoint returns all of the gateway information within a `body` obejcts in the `data` key. This entity
/// allows us to parse all the things with JSONDecoder.
///
private struct PaymentGatewayEnvelope: Decodable {
    private enum CodingKeys: String, CodingKey {
        case paymentGateway = "data"
    }

    let paymentGateway: PaymentGateway
}
