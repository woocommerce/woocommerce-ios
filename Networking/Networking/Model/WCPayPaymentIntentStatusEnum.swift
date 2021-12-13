import Foundation
import Codegen

/// Represents all of the possible WCPay Payment Intent Statuses in enum form
/// See https://stripe.com/docs/payments/intents#intent-statuses
/// See also https://stripe.com/docs/api/payment_intents/object#payment_intent_object-status
///
public enum WCPayPaymentIntentStatusEnum: Decodable, Hashable, GeneratedFakeable {
    /// When the PaymentIntent is created, it has a status of `requiresPaymentMethod` until a payment method is attached.
    case requiresPaymentMethod
    /// After the customer provides their payment information, the PaymentIntent is ready to be confirmed.
    /// Generally this state is skipped because payment method information is submitted at the same time that the payment is confirmed.
    case requiresConfirmation
    /// If the payment requires additional actions, such as authenticating with 3D Secure, the PaymentIntent has a status of `requiresAction`
    case requiresAction
    /// Once required actions are handled, the PaymentIntent moves to `processing`. While for some payment methods (e.g., cards)
    /// processing can be quick, other types of payment methods can take up to a few days to process.
    case processing
    /// If a card is merely authorized (and not immediately captured), the PaymentIntent status will transition to `requires_capture`
    case requiresCapture
    /// You may cancel a PaymentIntent at any point before it is `processing` or `succeeded`. This invalidates the PaymentIntent
    /// for future payment attempts, and cannot be undone. If any funds have been held, cancellation returns those funds.
    case canceled
    /// A PaymentIntent with a status of `succeeded` means that the payment flow it is driving is complete.
    /// The funds are now in the merchant's account and they can confidently fulfill the order.
    /// If you need to refund the customer, you should use the Refunds API.
    case succeeded
    /// An unrecognized response was returned for the payment intent status field.
    case unknown
}

/// RawRepresentable Conformance
///
extension WCPayPaymentIntentStatusEnum: RawRepresentable {

    /// Designated Initializer. Takes the string in the response and returns the enum
    /// assocated with that value. If not recognized, returns .unknown
    ///
    public init(rawValue: String) {
        switch rawValue {
        case Keys.requiresPaymentMethod:
            self = .requiresPaymentMethod
        case Keys.requiresConfirmation:
            self = .requiresConfirmation
        case Keys.requiresAction:
            self = .requiresAction
        case Keys.processing:
            self = .processing
        case Keys.requiresCapture:
            self = .requiresCapture
        case Keys.canceled:
            self = .canceled
        case Keys.succeeded:
            self = .succeeded
        default:
            self = .unknown
        }
    }

    /// Returns the current Enum Case's raw value
    ///
    public var rawValue: String {
        switch self {
        case .requiresPaymentMethod: return Keys.requiresPaymentMethod
        case .requiresConfirmation:  return Keys.requiresConfirmation
        case .requiresAction:        return Keys.requiresAction
        case .processing:            return Keys.processing
        case .requiresCapture:       return Keys.requiresCapture
        case .canceled:              return Keys.canceled
        case .succeeded:             return Keys.succeeded
        case .unknown:               return Keys.unknown
        }
    }
}

/// Enum containing all possible payment intent status keys
///
private enum Keys {
    static let requiresPaymentMethod = "requires_payment_method"
    static let requiresConfirmation = "requires_confirmation"
    static let requiresAction = "requires_action"
    static let processing = "processing"
    static let requiresCapture = "requires_capture"
    static let canceled = "canceled"
    static let succeeded = "succeeded"
    static let unknown = "UNKNOWN"
}
