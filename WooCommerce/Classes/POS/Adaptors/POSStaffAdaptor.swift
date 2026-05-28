import CocoaLumberjackSwift
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
                throw .flagDisabledServerSide
            case .unknown(let code, _, _) where code == "rest_forbidden":
                throw .adminMissingCapability
            default:
                throw .transient(retryable: true)
            }
        } catch let error as WordPressApiError {
            // WC REST returns its own error codes that DotcomValidator doesn't recognise
            // (the body has `code` rather than `error`). POSStaffMapper retries the decode
            // as WordPressApiError so we can branch on the specific code here.
            if case .unknown(let code, _) = error, Self.isAuthDenialCode(code) {
                throw .adminMissingCapability
            }
            throw .transient(retryable: true)
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
            return .flagDisabledServerSide
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
