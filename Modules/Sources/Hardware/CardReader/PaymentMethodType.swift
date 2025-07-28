/// PaymentMethodType defines supported hardware payment types.
/// Mirrors supported types from StripeTerminal.PaymentMethodType https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPPaymentMethodType.html
///
public enum PaymentMethodType {
    case cardPresent
    case interacPresent
}
