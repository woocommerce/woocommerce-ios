import Foundation
import Codegen

/// Represents a component in a Composite Product
///
public struct ProductCompositeComponent: Codable, Equatable, GeneratedCopiable, GeneratedFakeable {
    /// Component ID.
    public let componentID: String

    /// Title of the component.
    public let title: String

    /// Description of the component.
    public let description: String

    /// URL of the image associated with this component.
    public let imageURL: String

    /// Query type (product or category IDs) associated with the component options.
    public let optionType: CompositeComponentOptionType

    /// Product IDs or category IDs to use for populating component options.
    public let optionIDs: [Int64]

    /// The product ID of the default/pre-selected component option.
    public let defaultOptionID: String

    /// ProductCompositeComponent struct initializer
    ///
    public init(componentID: String,
                title: String,
                description: String,
                imageURL: String,
                optionType: CompositeComponentOptionType,
                optionIDs: [Int64],
                defaultOptionID: String) {
        self.componentID = componentID
        self.title = title
        self.description = description
        self.imageURL = imageURL
        self.optionType = optionType
        self.optionIDs = optionIDs
        self.defaultOptionID = defaultOptionID
    }

    /// The public initializer for ProductCompositeComponent.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let componentID = try container.decode(String.self, forKey: .componentID)
        let title = try container.decode(String.self, forKey: .title)
        let description = try container.decode(String.self, forKey: .description)
        let imageURL = try container.decode(String.self, forKey: .imageURL)
        let optionType = try container.decode(CompositeComponentOptionType.self, forKey: .optionType)
        let optionIDs = try container.decode([Int64].self, forKey: .optionIDs)

        // Default option ID can be Int or String.
        // The field value is an empty string if no default option is set.
        let defaultOptionID = container.failsafeDecodeIfPresent(stringForKey: .defaultOptionID) ?? ""

        self.init(componentID: componentID,
                  title: title,
                  description: description,
                  imageURL: imageURL,
                  optionType: optionType,
                  optionIDs: optionIDs,
                  defaultOptionID: defaultOptionID)
    }
}

/// Defines all of the ProductCompositeComponent CodingKeys
///
private extension ProductCompositeComponent {

    enum CodingKeys: String, CodingKey {
        case componentID     = "id"
        case title
        case description
        case imageURL        = "thumbnail_src"
        case optionType      = "query_type"
        case optionIDs       = "query_ids"
        case defaultOptionID = "default_option_id"
    }
}

/// Represents all query types for component options in a Composite product
///
public enum CompositeComponentOptionType: String, Codable, GeneratedFakeable {
    case productIDs     = "product_ids"
    case categoryIDs    = "category_ids"
}
