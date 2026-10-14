/// Represents the address used to calculate the taxes
///
public enum TaxBasedOnSetting: Sendable {
    case customerShippingAddress
    case customerBillingAddress
    case shopBaseAddress
}
