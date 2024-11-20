import Foundation
import Codegen

/// Represents a predefined option in Shipping Labels for the WooCommerce Shipping extension.
///
public struct WooShippingPredefinedOption: Equatable, GeneratedFakeable {

    /// The title of the predefined option. It works like an ID, and it is unique.
    public let title: String

    /// The ID of the predefined option (shipping provider), e.g. "usps". This is required for activating predefined packages remotely.
    public let providerID: String

    /// List of predefined packages
    public let predefinedPackages: [WooShippingPredefinedPackage]

    public init(title: String, providerID: String, predefinedPackages: [WooShippingPredefinedPackage]) {
        self.title = title
        self.providerID = providerID
        self.predefinedPackages = predefinedPackages
    }
}

// MARK: Decodable
extension WooShippingPredefinedOption: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let title = try container.decode(String.self, forKey: .title)
        let predefinedPackages = try container.decodeIfPresent([WooShippingPredefinedPackage].self, forKey: .predefinedPackages) ?? []
        let providerID = try container.decodeIfPresent(String.self, forKey: .providerID) ?? ""

        self.init(title: title, providerID: providerID, predefinedPackages: predefinedPackages)
    }

    private enum CodingKeys: String, CodingKey {
        case title
        case predefinedPackages
        case providerID
    }
}
