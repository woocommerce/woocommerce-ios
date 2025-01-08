import Foundation

/// View Model for a Variation Attribute.
public struct VariationAttributeViewModel: Equatable {

    /// Attribute name
    ///
    public let name: String

    /// Attribute value
    ///
    public let value: String?

    /// Returns the attribute value, or "Any \(name)" if the attribute value is nil or empty
    ///
    public var nameOrValue: String {
        guard let value = value, !value.isEmpty else {
            return String(format: Localization.anyAttributeFormat, name)
        }
        return value
    }

    public init(name: String, value: String? = nil) {
        self.name = name
        self.value = value
    }

    public init(orderItemAttribute: OrderItemAttribute) {
        self.init(name: orderItemAttribute.name, value: orderItemAttribute.value)
    }

    init(productVariationAttribute: ProductVariationAttribute) {
        self.init(name: productVariationAttribute.name, value: productVariationAttribute.option)
    }
}

extension VariationAttributeViewModel {
    enum Localization {
        static let anyAttributeFormat =
            NSLocalizedString("Any %1$@", comment: "Format of a product variation attribute description where the attribute is set to any value.")
    }
}
