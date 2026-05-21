import enum WooFoundation.CountryCode
import struct Yosemite.CardPresentPaymentsConfiguration

extension CardPresentPaymentsConfiguration {
    /// Whether card-present payments (external readers + Tap to Pay) should be exposed in POS
    /// for the merchant's store.
    ///
    /// Follows the underlying `isSupportedCountry` flag from the IPP configuration with one
    /// explicit per-country override: Canada is temporarily excluded from POS card payments
    /// pending Interac support, even though `CardPresentPaymentsConfiguration` reports CA as
    /// supported for the legacy (non-POS) in-person-payments flow.
    ///
    /// TODO: Remove the CA exclusion once Interac payments land in POS.
    var isPOSCardPaymentEnabled: Bool {
        guard isSupportedCountry else { return false }
        return countryCode != .CA
    }
}
