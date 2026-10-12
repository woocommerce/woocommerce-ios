import Foundation
import protocol Alamofire.URLRequestConvertible

extension URLRequestConvertible {
    /// Path of a network request in `Remote` for analyzing the decoding errors.
    var pathForAnalytics: String? {
        if let jetpackRequest = originalResponseRequest as? JetpackRequest {
            return jetpackRequest.path
        } else if let dotcomRequest = originalResponseRequest as? DotcomRequest {
            return dotcomRequest.path
        } else {
            return nil
        }
    }
}
