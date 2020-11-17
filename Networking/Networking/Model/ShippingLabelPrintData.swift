import Foundation

/// Shipping label data for printing
///
public struct ShippingLabelPrintData: Decodable, Equatable {
    /// The media type of shipping label document.
    public let mimeType: String

    /// The content of shipping label document for printing, with Base64 encoding.
    public let base64Content: String
}

/// Defines all of the ShippingLabelPrintData CodingKeys
///
private extension ShippingLabelPrintData {
    enum CodingKeys: String, CodingKey {
        case mimeType = "mimeType"
        case base64Content = "b64Content"
    }
}
