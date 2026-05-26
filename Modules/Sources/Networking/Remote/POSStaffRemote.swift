import Foundation

/// POS Staff: Remote Endpoints
///
/// Provides the single endpoint backing the M1 server-side design (see
/// https://peacockp2.wordpress.com/?p=34760): `GET /wc-pos/v1/staff` returns the
/// staff list with PBKDF2-hashed PINs. Mobile caches the response in the
/// Keychain and validates PIN entry locally — there is no remote PIN endpoint.
public final class POSStaffRemote: Remote {

    /// Fetches the POS staff list, including PBKDF2 salt + hash for each member that has a PIN configured.
    ///
    /// - Parameter siteID: Site for which to fetch the staff list.
    /// - Returns: The list of POS staff members.
    /// - Throws: `POSAuthError` when the backend returns a known POS error code,
    ///   or `POSAuthError.malformedResponse` when the body can't be decoded.
    public func fetchStaff(siteID: Int64) async throws -> [POSStaffMember] {
        let path = Constants.staffPath
        let request = JetpackRequest(wooApiVersion: .pointOfSaleV1,
                                     method: .get,
                                     siteID: siteID,
                                     path: path,
                                     availableAsRESTRequest: true)
        do {
            return try await enqueue(request, mapper: POSStaffMapper())
        } catch let posError as POSAuthError {
            throw posError
        } catch {
            throw POSAuthError.from(error)
        }
    }
}

private extension POSStaffRemote {
    enum Constants {
        /// Path segment under the `wc-pos/v1` namespace.
        static let staffPath = "staff"
    }
}
