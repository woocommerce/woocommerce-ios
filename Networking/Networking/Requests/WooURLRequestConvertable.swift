import Foundation
import Alamofire


public protocol WooURLRequestConvertable: URLRequestConvertible {

    /// Number of times to attempt a retry if this request recieves an error
    ///
    var retryAttempts: Int { get set }
}
