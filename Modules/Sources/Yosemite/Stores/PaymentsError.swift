import Foundation
import Networking

public enum PaymentsError: Error, LocalizedError {
    case noSuchChargeError(message: String)
    case orderPaymentCaptureError(message: String?)
    case otherError(error: AnyError)

    init(underlyingError error: Error) {
        guard let errorDetails = Self.unwrapError(error: error) else {
            self = .otherError(error: error.toAnyError)
            return
        }

        /// See if we recognize this NetworkError code
        ///
        self = errorDetails.asPaymentsError() ?? .otherError(error: error.toAnyError)
    }

    private static func unwrapError(error: Error) -> PaymentsErrorConvertible? {
        switch error {
        case let networkError as NetworkError:
            guard let code = networkError.apiErrorCode,
                  let errorCode = PaymentsErrorCode(rawValue: code) else {
                return nil
            }
            return PaymentsNetworkErrorDetails(code: errorCode, message: networkError.apiErrorMessage)
        default:
            return nil
        }
    }

    private struct PaymentsNetworkErrorDetails: PaymentsErrorConvertible {
        let code: PaymentsErrorCode
        let message: String?

        init(code: PaymentsErrorCode, message: String?) {
            self.code = code
            self.message = message
        }
    }


    public var errorDescription: String? {
        switch self {
        case .noSuchChargeError(let message):
            /// Return the message directly from the store
            /// "Error: No such charge: 'ch_3KMVapErrorERROR'"
            return message
        case .orderPaymentCaptureError(let message):
            /// Return the message directly from the store, e.g. in the case of fractional quantities, which are not allowed
            /// "Payment capture failed to complete with the following message: Error: Invalid integer: 2.5"
            return message ?? Localizations.defaultPaymentCaptureMessage
        case .otherError(let error):
            return error.localizedDescription
        }
    }

    enum Localizations {
        static let defaultPaymentCaptureMessage = NSLocalizedString(
            "An unexpected error occurred with the store's payment gateway when capturing payment for the order",
            comment: "Message presented when an unexpected error occurs with the store's payment gateway."
        )
    }
}

enum PaymentsErrorCode: String, Decodable {
    case getChargeError = "wcpay_get_charge"
    case wcpayCaptureError = "wcpay_capture_error"
    case unknown
}

protocol PaymentsErrorConvertible {
    var code: PaymentsErrorCode { get }
    var message: String? { get }
}

extension PaymentsErrorConvertible {
    func asPaymentsError() -> PaymentsError? {
        switch code {
        case .getChargeError:
            guard let message,
                  message.starts(with: "Error: No such charge") else {
                return nil
            }
            return .noSuchChargeError(message: message)
        case .wcpayCaptureError:
            return .orderPaymentCaptureError(message: message)
        case .unknown:
            return nil
        }
    }
}
