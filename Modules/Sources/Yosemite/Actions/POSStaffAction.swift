import Foundation
import Networking

/// POSStaffAction: actions supported by `POSStaffStore`.
///
/// In the M1 server-side design the only POS auth-related remote surface is the
/// staff list endpoint. PIN validation is local on-device against the cached hashes.
public enum POSStaffAction: Action {

    /// Fetches the POS staff list (with PBKDF2 hashes) from `GET /wc-pos/v1/staff`.
    case fetchStaff(siteID: Int64,
                    onCompletion: (Result<[POSStaffMember], Error>) -> Void)
}
