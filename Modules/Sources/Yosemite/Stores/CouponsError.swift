import Foundation
import Networking

public struct CouponsError: Error, LocalizedError {
    public let code: String = Constants.invalidCouponCode
    public let message: String
    public let underlyingError: Error

    public init?(underlyingError error: Error) {
        switch error {
        case let networkError as NetworkError:
            guard networkError.apiErrorCode == Constants.invalidCouponCode else {
                return nil
            }
            self.message = networkError.apiErrorMessage ?? Localizations.defaultCouponsError
            self.underlyingError = error
        default:
            return nil
        }
    }

    public init(message: String, underlyingError: Error) {
        self.message = message
        self.underlyingError = underlyingError
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
