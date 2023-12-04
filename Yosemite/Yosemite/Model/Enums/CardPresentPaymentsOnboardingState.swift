import WooFoundation

/// Represents the possible states for onboarding to In-Person payments
public enum CardPresentPaymentOnboardingState: Equatable {
    /// The app is loading the required data to check for the current state
    ///
    case loading

    /// All the requirements are temporarily met and the feature is ready to use.
    /// While the account is in good standing, additional information might be required if a payment volume threshold is reached
    ///
    case enabled

    /// All the requirements are met and the feature is ready to use
    ///
    case completed(plugin: CardPresentPaymentsPluginState)

    /// There is more than one plugin installed and activated. The user must deactivate one.
    /// `pluginSelectionWasCleared` being true means that there was one plugin selected for payments
    /// but that selection was just cleared (e.g when in settings asking to choose a plugin again)
    /// 
    case selectPlugin(pluginSelectionWasCleared: Bool)

    /// Store is not located in one of the supported countries.
    ///
    case countryNotSupported(countryCode: CountryCode)

    /// Only Stripe is installed and activated, but the store is not located in one of the supported countries for Stripe (but it is for WCPay).
    ///
    case countryNotSupportedStripe(plugin: CardPresentPaymentsPlugin, countryCode: CountryCode)

    /// No CPP plugin is installed on the store.
    ///
    case pluginNotInstalled

    /// CPP plugin is installed on the store, but the version is out-dated and doesn't contain required APIs for card present payments.
    ///
    case pluginUnsupportedVersion(plugin: CardPresentPaymentsPlugin)

    /// CPP plugin is installed on the store but is not activated.
    ///
    case pluginNotActivated(plugin: CardPresentPaymentsPlugin)

    /// CPP plugin is installed and activated but requires to be setup first.
    ///
    case pluginSetupNotCompleted(plugin: CardPresentPaymentsPlugin)

    /// This is a bit special case: The plugin is set to test mode but the connected Stripe account is a real (live) account.
    /// Connecting to a reader or accepting payments is not supported in this state.
    ///
    case pluginInTestModeWithLiveStripeAccount(plugin: CardPresentPaymentsPlugin)

    /// The connected Stripe account has not been reviewed by Stripe yet. This is a temporary state and the user needs to wait.
    ///
    case stripeAccountUnderReview(plugin: CardPresentPaymentsPlugin)

    /// There are some pending requirements on the connected Stripe account. The merchant still has some time before the deadline to fix them expires.
    /// In-person payments should work without issues.
    ///
    case stripeAccountPendingRequirement(plugin: CardPresentPaymentsPlugin, deadline: Date?)

    /// There are some overdue requirements on the connected Stripe account. Connecting to a reader or accepting payments is not supported in this state.
    ///
    case stripeAccountOverdueRequirement(plugin: CardPresentPaymentsPlugin)

    /// The Stripe account was rejected by Stripe.
    /// This can happen for example when the account is flagged as fraudulent or the merchant violates the terms of service.
    ///
    case stripeAccountRejected(plugin: CardPresentPaymentsPlugin)

    /// The Cash on Delivery payment gateway is missing or disabled
    /// Enabling Cash on Delivery is not essential for Card Present Payments, but allows web store customers to place orders and pay by card in person.
    ///
    case codPaymentGatewayNotSetUp(plugin: CardPresentPaymentsPlugin)

    /// Generic error - for example, one of the requests failed.
    ///
    case genericError

    /// Internet connection is not available.
    ///
    case noConnectionError
}

extension CardPresentPaymentOnboardingState {
    public var reasonForAnalytics: String {
        switch self {
        case .loading:
            return "loading"
        case .enabled:
            return "enabled"
        case .completed:
            return "completed"
        case .selectPlugin:
            return "multiple_payment_providers_conflict"
        case .countryNotSupported(countryCode: _):
            return "country_not_supported"
        case .countryNotSupportedStripe(countryCode: _):
            return "country_not_supported"
        case .pluginNotInstalled:
            return "wcpay_not_installed"
        case .pluginUnsupportedVersion:
            return "wcpay_unsupported_version"
        case .pluginNotActivated:
            return "wcpay_not_activated"
        case .pluginSetupNotCompleted(let plugin):
            return plugin == .wcPay ? "wcpay_setup_not_completed" : "stripe_extension_not_setup"
        case .pluginInTestModeWithLiveStripeAccount:
            return "wcpay_in_test_mode_with_live_account"
        case .stripeAccountUnderReview:
            return "account_under_review"
        case .stripeAccountPendingRequirement(deadline: _):
            return "account_pending_requirements"
        case .stripeAccountOverdueRequirement:
            return "account_overdue_requirements"
        case .stripeAccountRejected:
            return "account_rejected"
        case .codPaymentGatewayNotSetUp:
            return "cash_on_delivery_disabled"
        case .genericError:
            return "generic_error"
        case .noConnectionError:
            return "no_connection_error"
        }
    }

    public var shouldTrackOnboardingStepEvents: Bool {
        switch self {
        case .loading:
            return false
        default:
            return true
        }
    }

    public var isCompleted: Bool {
        if case .completed(_) = self {
            return true
        } else {
            return false
        }
    }

    public var isSelectPlugin: Bool {
        if case .selectPlugin = self {
            return true
        } else {
            return false
        }
    }

    public var isCountryNotSupported: Bool {
        if case .countryNotSupported(_) = self {
            return true
        } else {
            return false
        }
    }
}
