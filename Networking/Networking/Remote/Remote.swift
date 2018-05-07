import Foundation
import Alamofire


/// Represents a collection of Remote Endpoints
///
public class Remote {

    /// WordPress.com Credentials.
    ///
    let credentials: Credentials

    /// Networking Wrapper. Useful for Unit Testing purposes.
    ///
    let network: Network


    /// Initializes the Remote Instance with the specified Credentials, and, by default, our Networking requests will be handled
    /// by Alamofire.
    ///
    public convenience init(credentials: Credentials) {
        self.init(credentials: credentials, network: AlamofireWrapper())
    }

    /// Designated Initializer.
    ///
    /// - Parameters:
    ///     - credentials: Credentials to be used in order to authenticate every request.
    ///     - network: Network Wrapper, in charge of actually enqueueing a given network request.
    ///
    init(credentials: Credentials, network: Network) {
        self.credentials = credentials
        self.network = network
    }


    /// Enqueues the specified Network Request.
    ///
    /// - Parameters:
    ///     - request: Request that should be performed.
    ///     - completion: Closure to be executed upon completion.
    ///
    func enqueue(_ request: URLRequestConvertible, completion: @escaping (Any?, Error?) -> Void) {
        let authenticated = AuthenticatedRequest(credentials: credentials, request: request)
        network.enqueue(authenticated, completion: completion)
    }
}


/// Default Remote Errors
///
enum RemoteError: Error {

    /// Triggered whenever the backend's response isn't in the expected format.
    ///
    case unknownFormat
}
