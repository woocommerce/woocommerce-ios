import Foundation
import Alamofire
import enum Networking.NetworkError
import enum Networking.DotcomError

extension Error {
    /// Extracts the most relevant error code from the error hierarchy.
    /// Handles NetworkError, AFError, DotcomError, SiteCredentialLoginError, and falls back to NSError.code.
    var errorCode: Int {
        if let networkError = self as? NetworkError, let code = networkError.responseCode {
            return code
        } else if let afError = self as? AFError {
            if let responseCode = afError.responseCode {
                return responseCode
            } else if let underlyingError = afError.underlyingError as? NSError {
                return underlyingError.code
            }
        } else if case let .unknown(_, _, data) = self as? DotcomError,
                  let status = data?["status"]?.description,
                  let statusCode = Int(status) {
            return statusCode
        } else if let loginError = self as? SiteCredentialLoginError {
            return loginError.underlyingError.code
        }
        return (self as NSError).code
    }

    /// Extracts the error domain, handling AFError's underlying error.
    var errorDomain: String {
        if let afError = self as? AFError,
           let underlyingError = afError.underlyingError as? NSError {
            return underlyingError.domain
        }
        return (self as NSError).domain
    }

    /// Formatted technical details string including error code and domain.
    var formattedTechnicalDetails: String {
        "Error Code: \(errorCode.description), Domain: \(errorDomain)\n\(self)"
    }
}
