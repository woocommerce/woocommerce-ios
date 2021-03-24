import Foundation

/// Represents a predefined option in Shipping Labels.
///
public struct ShippingLabelPredefinedOption: Equatable, GeneratedFakeable {

    /// The title of the predefined option
    public let title: String

    /// List of predefined packages
    public let predefinedPackages: [ShippingLabelPredefinedPackage]


    public init(title: String, predefinedPackages: [ShippingLabelPredefinedPackage]) {
        self.title = title
        self.predefinedPackages = predefinedPackages
    }
}

// MARK: Decodable
extension ShippingLabelPredefinedOption: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let title = try container.decode(String.self, forKey: .title)
        let predefinedPackages = try container.decodeIfPresent([ShippingLabelPredefinedPackage].self, forKey: .predefinedPackages) ?? []

        self.init(title: title, predefinedPackages: predefinedPackages)
    }

    private enum CodingKeys: String, CodingKey {
        case title
        case predefinedPackages
    }
}
