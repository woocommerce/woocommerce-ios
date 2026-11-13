/// Describes whether EU product identifiers are required for a WooShipping route.
public enum WooShippingEUProductIdentifiersRequirement: Equatable {
    case required(prefills: [Int64: WooShippingEUProductIdentifiers])
    case notRequired
    case pluginOutdated
}
