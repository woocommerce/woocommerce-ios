import Foundation
import Networking

public struct CouponsError: Error, LocalizedError {
    public let code: String = Constants.invalidCouponCode
    public let message: String
    public let underlyingError: Error

    public init?(underlyingError error: Error) {
        switch error {
        case DotcomError.unknown(Constants.invalidCouponCode, let message, _):
            self.message = message ?? Localizations.defaultCouponsError
            self.underlyingError = error
        case let NetworkError.unacceptableStatusCode(_, response):
            guard let response,
                  let errorDetails = try? JSONDecoder().decode(ErrorDetails.self, from: response),
                  errorDetails.code == Constants.invalidCouponCode
            else {
                return nil
            }
            self.message = errorDetails.message ?? Localizations.defaultCouponsError
            self.underlyingError = error
        default:
            return nil
        }
    }

    public init(message: String, underlyingError: Error) {
        self.message = message
        self.underlyingError = underlyingError
    }


    private struct ErrorDetails: Decodable {
        let code: String
        let message: String?

        enum CodingKeys: CodingKey {
            case code
            case message
        }
    }

    enum Localizations {
        static let defaultCouponsError = NSLocalizedString(
            "couponsError.default.title",
            value: "The coupon could not be applied due to an unexpected error.",
            comment: "A default error when coupon application failed."
        )
    }

    struct Constants {
        static let invalidCouponCode = "woocommerce_rest_invalid_coupon"
    }
}
