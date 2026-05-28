import CocoaLumberjackSwift
import Foundation
import Networking
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
            if case .unknown(let code, _) = error,
               code.hasPrefix("woocommerce_rest_cannot") || code == "rest_forbidden" {
                throw .adminMissingCapability
            }
            throw .transient(retryable: true)
        } catch {
            throw .transient(retryable: true)
        }
    }
}
