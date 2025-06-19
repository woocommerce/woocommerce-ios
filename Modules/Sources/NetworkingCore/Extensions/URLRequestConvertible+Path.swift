import Foundation
import protocol Alamofire.URLRequestConvertible

extension URLRequestConvertible {
    /// Path of a network request in `Remote` for analyzing the decoding errors.
    var pathForAnalytics: String? {
        if let jetpackRequest = self as? JetpackRequest {
            return jetpackRequest.path
        } else if let dotcomRequest = self as? DotcomRequest {
            return dotcomRequest.path
        } else {
            return nil
        }
    }
}
