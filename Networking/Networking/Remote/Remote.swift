import Foundation
import Alamofire


/// Represents a collection of Remote Endpoints
///
public class Remote {

    /// WordPress.com Credentials.
    ///
    let credentials: Credentials

    /// Networking Wrapper: Dependency Injection Mechanism, useful for Unit Testing purposes.
    ///
    let network: Network


    /// Initializes the Remote Instance with the specified Credentials, and, by default, our Networking requests will be handled
    /// by Alamofire.
    ///
    public convenience init(credentials: Credentials) {
        self.init(credentials: credentials, network: AlamofireNetwork())
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
    /// - Important:
    ///     - Authentication Headers will be injected, based on the Remote's Credentials.
    ///
    /// - Parameters:
    ///     - request: Request that should be performed.
    ///     - completion: Closure to be executed upon completion. Will receive the JSON Parsed Response (if successful)
    ///
    func enqueue(_ request: URLRequestConvertible, completion: @escaping (Any?, Error?) -> Void) {
        let authenticated = AuthenticatedRequest(credentials: credentials, request: request)
        network.responseJSON(for: authenticated) { (payload, error) in
            guard let payload = payload else {
                completion(nil, error ?? NetworkError.emptyResponse)
                return
            }

            completion(payload, error)
        }
    }


    /// Enqueues the specified Network Request.
    ///
    /// - Important:
    ///     - Authentication Headers will be injected, based on the Remote's Credentials.
    ///     - Parsing will be performed by the Mapper.
    ///
    /// - Parameters:
    ///     - request: Request that should be performed.
    ///     - mapper: Mapper entitity that will be used to attempt to parse the Backend's Response.
    ///     - completion: Closure to be executed upon completion.
    ///
    func enqueue<M: Mapper>(_ request: URLRequestConvertible, mapper: M, completion: @escaping (M.Output?, Error?) -> Void) {
        let authenticated = AuthenticatedRequest(credentials: credentials, request: request)
        network.responseData(for: authenticated) { (data, error) in
            guard let data = data else {
                completion(nil, error ?? NetworkError.emptyResponse)
                return
            }

            do {
                let parsed = try mapper.map(response: data)
                completion(parsed, nil)
            } catch {
                NSLog("<> Mapping Error: \(error)")
                completion(nil, error)
            }
        }
    }
}
