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
        network.responseData(for: request) { (data, networError) in
            guard let data = data else {
                completion(nil, networError)
                return
            }

            if let dotcomError = DotcomValidator.error(from: data) {
                self.dotcomErrorWasReceived(error: dotcomError, for: request)
                completion(nil, dotcomError)
                return
            }

            do {
                let document = try JSONSerialization.jsonObject(with: data, options: [])
                completion(document, nil)
            } catch {
                completion(nil, error)
            }
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
        network.responseData(for: request) { (data, networkError) in
            guard let data = data else {
                completion(nil, networkError)
                return
            }

            if let dotcomError = DotcomValidator.error(from: data) {
                self.dotcomErrorWasReceived(error: dotcomError, for: request)
                completion(nil, dotcomError)
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

    /// Handles *all* of the DotcomError(s) that are successfully parsed.
    ///
    func dotcomErrorWasReceived(error: Error, for request: URLRequestConvertible) {
        guard let dotcomError = error as? DotcomError else {
            return
        }

        switch dotcomError {
        case .requestFailed where request is JetpackRequest:
            publishJetpackTimeoutNotification(error: dotcomError)
        case .invalidToken:
            publishInvalidTokenNotification(error: dotcomError)
        default:
            break
        }
    }


    /// Publishes a `Jetpack Timeout` Notification.
    ///
    private func publishJetpackTimeoutNotification(error: DotcomError) {
        NotificationCenter.default.post(name: .RemoteDidReceiveJetpackTimeoutError, object: error, userInfo: nil)
    }

    /// Publishes an `Invalid Token` Notification.
    ///
    private func publishInvalidTokenNotification(error: DotcomError) {
        NotificationCenter.default.post(name: .RemoteDidReceiveInvalidTokenError, object: error, userInfo: nil)
    }
}


// MARK: - Remote Notifications
//
public extension NSNotification.Name {

    /// Posted whenever an Invalid Token Error is received.
    ///
    public static let RemoteDidReceiveInvalidTokenError = NSNotification.Name(rawValue: "RemoteDidReceiveInvalidTokenError")

    /// Posted whenever a Jetpack Timeout is received.
    ///
    public static let RemoteDidReceiveJetpackTimeoutError = NSNotification.Name(rawValue: "RemoteDidReceiveJetpackTimeoutError")
}
