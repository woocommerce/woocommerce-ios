import Foundation
import Codegen

/// Represents a component in a Composite Product
///
public struct ProductCompositeComponent: Codable, Equatable, GeneratedCopiable, GeneratedFakeable {
    /// Component ID.
    public let componentID: Int64

    /// Title of the component.
    public let title: String

    /// URL of the image associated with this component.
    public let imageURL: String

    /// Query type (product or category IDs) associated with the component options.
    public let optionType: CompositeComponentOptionType

    /// Product IDs or category IDs to use for populating component options.
    public let optionIDs: [Int64]

    /// ProductCompositeComponent struct initializer
    ///
    public init(componentID: Int64,
                title: String,
                imageURL: String,
                optionType: CompositeComponentOptionType,
                optionIDs: [Int64]) {
        self.componentID = componentID
        self.title = title
        self.imageURL = imageURL
        self.optionType = optionType
        self.optionIDs = optionIDs
    }
}

/// Defines all of the ProductCompositeComponent CodingKeys
///
private extension ProductCompositeComponent {

    enum CodingKeys: String, CodingKey {
        case componentID    = "id"
        case title
        case imageURL       = "thumbnail_src"
        case optionType     = "query_type"
        case optionIDs      = "query_ids"
    }
}

/// Represents all query types for component options in a Composite product
///
public enum CompositeComponentOptionType: String, Codable, GeneratedFakeable {
    case productIDs     = "product_ids"
    case categoryIDs    = "category_ids"
}
