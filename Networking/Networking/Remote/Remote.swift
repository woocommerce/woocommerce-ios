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


    /// Enqueues the specified Network Request: Authentication Headers will be injected!.
    ///
    /// - Parameters:
    ///     - request: Request that should be performed.
    ///     - completion: Closure to be executed upon completion.
    ///
    func enqueue(_ request: URLRequestConvertible, completion: @escaping (Any?, Error?) -> Void) {
        let authenticated = AuthenticatedRequest(credentials: credentials, request: request)
        network.enqueue(authenticated, completion: completion)
    }


    /// Enqueues the specified Network Request: Authentication Headers will be injected!.
    ///
    /// - Parameters:
    ///     - request: Request that should be performed.
    ///     - mapper: Mapper entitity that will be used to attempt to parse the Backend's Response.
    ///     - completion: Closure to be executed upon completion.
    ///
    func enqueue<M: Mapper>(_ request: URLRequestConvertible, mapper: M, completion: @escaping (M.T?, Error?) -> Void) {
        enqueue(request) { (response, error) in
            if let error = error {
                completion(nil, error)
                return
            }

            guard let payload = response as? [String: Any], let parsed = try? mapper.map(response: payload) else {
                completion(nil, MappingError.unknownFormat)
                return
            }

            completion(parsed, nil)
        }
    }
}
