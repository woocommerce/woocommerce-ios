import Foundation
import Alamofire
import enum NetworkingCore.NetworkError
import protocol WooFoundationCore.WooAnalyticsEventPropertyType

extension Error {
    var errorCode: Int {
        if let error = self as? NetworkError, let code = error.responseCode {
            return code
        } else if let error = self as? AFError, let code = error.responseCode {
            return code
        }

        return (self as NSError).code
    }

    var errorDescription: String {
        return String(describing: self)
    }

    var analyticsProperties: [String: WooAnalyticsEventPropertyType] {
        return [
            Properties.errorDescription: errorDescription,
            Properties.errorCode: errorCode
        ]
    }
}

fileprivate enum Properties {
    static let errorDescription = "error_description"
    static let errorCode = "error_code"
}
