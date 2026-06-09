import CocoaLumberjackSwift
import Combine
import Foundation
import Networking
import NetworkingCore
import PointOfSale

/// Test-seam wrapping `POSStaffRemote` so the adaptor can be unit-tested with a mock.
///
protocol POSStaffRemoteProtocol: Sendable {
    func fetchStaff(siteID: Int64) async throws -> [POSStaffMember]
}

extension POSStaffRemote: POSStaffRemoteProtocol {}

/// Concrete `POSStaffFetching` in the app target. Calls `POSStaffRemote` and maps Networking
/// errors to the typed `POSStaffFetchError` so PointOfSale callers can branch by intent.
///
/// HTTP 401/403, expired tokens, and `woocommerce_rest_cannot_view` map to `.adminMissingCapability`.
final class POSStaffAdaptor: POSStaffFetching {
    private let remote: POSStaffRemoteProtocol

    init(remote: POSStaffRemoteProtocol) {
        self.remote = remote
    }

    convenience init(network: Network) {
        self.init(remote: POSStaffRemote(network: network))
    }

    convenience init?(credentials: Credentials?,
                      selectedSite: AnyPublisher<JetpackSite?, Never>,
                      appPasswordSupportState: AnyPublisher<Bool, Never>) {
        guard let credentials else {
            DDLogError("⛔️ Could not create POSStaffAdaptor due to not finding credentials")
            return nil
        }
        let network = AlamofireNetwork(credentials: credentials,
                                       selectedSite: selectedSite,
                                       appPasswordSupportState: appPasswordSupportState)
        self.init(network: network)
    }

    func fetchStaff(siteID: Int64) async throws(POSStaffFetchError) -> [POSStaffMember] {
        do {
            return try await remote.fetchStaff(siteID: siteID)
        } catch let error as DecodingError {
            DDLogError("POS staff decode failure: \(error)")
            throw .malformedResponse
        } catch let error as DotcomError {
            // Reached when the request tunnels through Jetpack and DotcomValidator parses the body.
            switch error {
            case .unauthorized, .invalidToken:
                throw .adminMissingCapability
            case .noRestRoute:
                throw .endpointUnavailable
            case .unknown(let code, _, _) where code == "rest_forbidden":
                throw .adminMissingCapability
            default:
                throw .transient(retryable: true)
            }
        } catch let error as NetworkError {
            // Reached when the request goes direct via the REST path (app-password sites).
            // The body code lives on `error.errorCode`; the HTTP status on `error.responseCode`.
            throw Self.classify(networkError: error)
        } catch {
            throw .transient(retryable: true)
        }
    }

    private static func classify(networkError error: NetworkError) -> POSStaffFetchError {
        if case .notFound = error, error.errorCode == "rest_no_route" {
            return .endpointUnavailable
        }
        if let code = error.errorCode, isAuthDenialCode(code) {
            return .adminMissingCapability
        }
        if let status = error.responseCode, status == 401 || status == 403 {
            return .adminMissingCapability
        }
        return .transient(retryable: true)
    }

    private static func isAuthDenialCode(_ code: String) -> Bool {
        code.hasPrefix("woocommerce_rest_cannot") || code == "rest_forbidden"
    }
}
