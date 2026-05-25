import Foundation

/// View Model for a Variation Attribute.
public struct VariationAttributeViewModel: Equatable {

    /// Attribute name
    ///
    public let name: String

    /// Attribute value
    ///
    public let value: String?

    /// Returns the attribute value, e.g. "100g", or "Any \(name)" if the attribute value is nil or empty
    ///
    public var nameOrValue: String {
        guard let value, !value.isEmpty else {
            return anyAttributeDescription
        }
        return value
    }

    /// Returns the named attribute value, e.g. "Size: 100g", or "Any \(name)" if the attribute value is nil or empty
    ///
    public var namedValue: String {
        guard let value, !value.isEmpty else {
            return anyAttributeDescription
        }
        return String(format: Localization.namedAttributeFormat, name, value)
    }

    private var anyAttributeDescription: String {
        String(format: Localization.anyAttributeFormat, name)
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
        static let anyAttributeFormat = NSLocalizedString(
            "Any %1$@",
            comment: "Format of a product variation attribute description where the attribute is set to any value."
        )

        static let namedAttributeFormat = NSLocalizedString(
            "variationAttributeView.namedAttributeFormat",
            value: "%1$@: %2$@",
            comment: "Format of a named variation attribute description. %1$@ is the attribute name, and %2$@ is the " +
            "attribute value. Displayed in a whole variation of a Coffee beans/grounds product, it could look like: +" +
            "'Roast: Dark, Size: 100g, Origin: Brazil, Any grind'"
        )
    }
}
