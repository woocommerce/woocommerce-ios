import Foundation
import enum Alamofire.AFError

extension Error {
    var isConnectivityError: Bool {
        if let afError = self as? AFError {
            if let underlyingError = afError.underlyingError {
                return underlyingError.isConnectivityError
            }
        }

        if let urlError = self as? URLError {
            return urlError.code == .notConnectedToInternet || urlError.code == .networkConnectionLost
        }

        let nsError = self as NSError
        if nsError.domain == NSURLErrorDomain {
            return nsError.code == NSURLErrorNotConnectedToInternet || nsError.code == NSURLErrorNetworkConnectionLost
        }

        return false
    }
}
