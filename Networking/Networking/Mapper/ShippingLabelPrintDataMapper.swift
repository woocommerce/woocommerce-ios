import Foundation


/// Mapper: Shipping Label Print Data
///
struct ShippingLabelPrintDataMapper: Mapper {
    /// (Attempts) to convert a dictionary into ShippingLabelPrintData.
    ///
    func map(response: Data) throws -> ShippingLabelPrintData {
        let decoder = JSONDecoder()
        return try decoder.decode(ShippingLabelPrintDataEnvelope.self, from: response).printData
    }
}

/// ShippingLabelPrintDataEnvelope Disposable Entity:
/// `Print Shipping Label` endpoint returns the shipping label document in the `data` key.
/// This entity allows us to do parse all the things with JSONDecoder.
///
private struct ShippingLabelPrintDataEnvelope: Decodable {
    let printData: ShippingLabelPrintData

    private enum CodingKeys: String, CodingKey {
        case printData = "data"
    }
}
