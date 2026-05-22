import enum WooFoundation.CountryCode
import struct Yosemite.CardPresentPaymentsConfiguration

public extension CardPresentPaymentsConfiguration {
    /// Whether card-present payments (external readers + Tap to Pay) should be exposed in POS
    /// for the merchant's store.
    ///
    /// Follows the underlying `isSupportedCountry` flag from the IPP configuration with one
    /// explicit per-country override: Canada is temporarily excluded from POS card payments
    /// pending Interac support, even though `CardPresentPaymentsConfiguration` reports CA as
    /// supported for the legacy (non-POS) in-person-payments flow.
    ///
    /// Public so the app-target `CardPresentPaymentService` (which implements
    /// `CardPresentPaymentFacade.isPOSCardPaymentEnabled`) can read it across the module
    /// boundary. The underlying `CardPresentPaymentsConfiguration` type is itself public in
    /// Yosemite, so widening this extension property to `public` doesn't expand the API surface
    /// any further than the parent type already does.
    ///
    /// TODO: Remove the CA exclusion once Interac payments land in POS.
    var isPOSCardPaymentEnabled: Bool {
        guard isSupportedCountry else { return false }
        return countryCode != .CA
    }
}
