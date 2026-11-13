import Foundation
import enum Alamofire.AFError
import enum Networking.BackgroundDownloadError

public extension Error {
    var isConnectivityError: Bool {
        if let backgroundDownloadError = self as? BackgroundDownloadError {
            switch backgroundDownloadError {
            case .downloadFailed(let error):
                return error.isConnectivityError
            default:
                return false
            }
        }

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
