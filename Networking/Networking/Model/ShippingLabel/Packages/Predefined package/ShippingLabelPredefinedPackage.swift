import Foundation

/// Represents a predefined package in Shipping Labels.
///
public struct ShippingLabelPredefinedPackage: Equatable, GeneratedFakeable {

    /// The id of the predefined package
    public let id: String

    /// The name of the package, like `USPS Priority Mail Boxes`
    public let title: String

    /// Defines if package is a box or a letter. By default is a box, so it's equal to `false`
    public let isLetter: Bool

    /// Will be a string formatted like this: ` 21.91 x 13.65 x 4.13`
    public let dimensions: String

    public init(id: String, title: String, isLetter: Bool, dimensions: String) {
        self.id = id
        self.title = title
        self.isLetter = isLetter
        self.dimensions = dimensions
    }
}

// MARK: Decodable
extension ShippingLabelPredefinedPackage: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let id = try container.decode(String.self, forKey: .id)
        let title = try container.decode(String.self, forKey: .title)
        let isLetter = try container.decodeIfPresent(Bool.self, forKey: .isLetter) ?? false
        let dimensions = try container.decode(String.self, forKey: .dimensions)

        self.init(id: id, title: title, isLetter: isLetter, dimensions: dimensions)
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case title = "name"
        case isLetter = "is_letter"
        case dimensions = "outer_dimensions"
    }
}
