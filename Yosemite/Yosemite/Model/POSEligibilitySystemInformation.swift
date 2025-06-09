import Networking
import Codegen
import enum WooFoundation.CurrencyCode

/// Store sytem information entity.
///
public struct POSEligibilitySystemInformation: GeneratedFakeable, GeneratedCopiable {
    /// Store plugins (Active, inactive)
    ///
    public let activePlugins: [SystemPlugin]

    /// Available in WooCommerce version 9.9.0 and later.
    public let enabledFeatures: [String]?

    /// Available in WooCommerce version 9.9.0 and later.
    public let currencyCode: CurrencyCode
}
