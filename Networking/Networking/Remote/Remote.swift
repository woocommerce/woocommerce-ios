import Foundation
import Alamofire
import CocoaLumberjack


/// Represents a collection of Remote Endpoints
///
public class Remote {

    /// Networking Wrapper: Dependency Injection Mechanism, useful for Unit Testing purposes.
    ///
    let network: Network


    /// Designated Initializer.
    ///
    /// - Parameters:
    ///     - credentials: Credentials to be used in order to authenticate every request.
    ///     - network: Network Wrapper, in charge of actually enqueueing a given network request.
    ///
    public init(network: Network) {
        self.network = network
    }


    /// Enqueues the specified Network Request.
    ///
    /// - Parameters:
    ///     - request: Request that should be performed.
    ///     - completion: Closure to be executed upon completion. Will receive the JSON Parsed Response (if successful)
    ///
    func enqueue(_ request: URLRequestConvertible, completion: @escaping (Any?, Error?) -> Void) {
        network.responseJSON(for: request) { (document, networkingError) in
            guard let document = document else {
                completion(nil, networkingError)
                return
            }

            if let applicationError = DotcomValidator.error(from: document) {
                self.applicationErrorWasReceived(error: applicationError)
                completion(nil, applicationError)
                return
            }

            completion(document, nil)
        }
    }


    /// Enqueues the specified Network Request.
    ///
    /// - Important:
    ///     - Parsing will be performed by the Mapper.
    ///
    /// - Parameters:
    ///     - request: Request that should be performed.
    ///     - mapper: Mapper entitity that will be used to attempt to parse the Backend's Response.
    ///     - completion: Closure to be executed upon completion.
    ///
    func enqueue<M: Mapper>(_ request: URLRequestConvertible, mapper: M, completion: @escaping (M.Output?, Error?) -> Void) {
        network.responseData(for: request) { (data, networkingError) in
            guard let data = data else {
                completion(nil, networkingError)
                return
            }

            if let applicationError = DotcomValidator.error(from: data) {
                self.applicationErrorWasReceived(error: applicationError)
                completion(nil, applicationError)
                return
            }

            do {
                let parsed = try mapper.map(response: data)
                completion(parsed, nil)
            } catch {
                DDLogError("<> Mapping Error: \(error)")
                completion(nil, error)
            }
        }
    }
}


// MARK: - Private Methods
//
private extension Remote {

    /// Publishes a `RemoteDidReceiveApplicationError` with the associated Error entity.
    ///
    func applicationErrorWasReceived(error: Error) {
        NotificationCenter.default.post(name: .RemoteDidReceiveApplicationError, object: error)
    }
}


// MARK: - Remote Notifications
//
public extension NSNotification.Name {

    /// Posted whenever a DotcomValidation Error is received. Allows us to implement a "Master Flow" Error Handler.
    ///
    public static let RemoteDidReceiveApplicationError = NSNotification.Name(rawValue: "RemoteDidReceiveApplicationError")
}
