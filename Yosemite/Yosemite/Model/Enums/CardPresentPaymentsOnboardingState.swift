/// Represents the possible states for onboarding to In-Person payments
public enum CardPresentPaymentOnboardingState: Equatable {
    /// All the requirements are met and the feature is ready to use
    ///
    case completed

    /// Store is not located in one of the supported countries.
    ///
    case countryNotSupported(countryCode: String)

    /// WCPay plugin is not installed on the store.
    ///
    case wcpayNotInstalled

    /// WCPay plugin is installed on the store, but the version is out-dated and doesn't contain required APIs for card present payments.
    ///
    case wcpayUnsupportedVersion

    /// WCPay is installed on the store but is not activated.
    ///
    case wcpayNotActivated

    /// WCPay is installed and activated but requires to be setup first.
    ///
    case wcpaySetupNotCompleted

    /// This is a bit special case: WCPay is set to "dev mode" but the connected Stripe account is in live mode.
    /// Connecting to a reader or accepting payments is not supported in this state.
    ///
    case wcpayInTestModeWithLiveStripeAccount

    /// The connected Stripe account has not been reviewed by Stripe yet. This is a temporary state and the user needs to wait.
    ///
    case stripeAccountUnderReview

    /// There are some pending requirements on the connected Stripe account. The merchant still has some time before the deadline to fix them expires.
    /// In-person payments should work without issues.
    ///
    case stripeAccountPendingRequirement

    /// There are some overdue requirements on the connected Stripe account. Connecting to a reader or accepting payments is not supported in this state.
    ///
    case stripeAccountOverdueRequirement

    /// The Stripe account was rejected by Stripe.
    /// This can happen for example when the account is flagged as fraudulent or the merchant violates the terms of service.
    ///
    case stripeAccountRejected

    /// Generic error - for example, one of the requests failed.
    ///
    case genericError

    /// Internet connection is not available.
    ///
    case noConnectionError
}
