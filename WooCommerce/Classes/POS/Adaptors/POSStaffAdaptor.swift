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
            case .unauthorized:
                throw .adminMissingCapability
            case .noRestRoute:
                throw .flagDisabledServerSide
            default:
                throw .transient(retryable: true)
            }
        } catch {
            throw .transient(retryable: true)
        }
    }
}
