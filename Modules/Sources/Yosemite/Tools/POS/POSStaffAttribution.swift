import Foundation
import struct Networking.MetaData

/// Operator (and optional manager-override approver) identifiers attached to a POS-originated
/// WC REST request so the order/refund/coupon timeline records which staff member acted.
///
/// Callers express "no attribution" by passing `nil` for the whole value rather than constructing
/// an instance with sentinel IDs. `metadata` is the single source of truth for the
/// `_pos_staff_user_id` / `_pos_override_staff_user_id` meta keys.
public struct POSStaffAttribution: Equatable, Sendable {
    public let staffUserID: Int64
    public let overrideApproverUserID: Int64?

    public init(staffUserID: Int64, overrideApproverUserID: Int64? = nil) {
        self.staffUserID = staffUserID
        self.overrideApproverUserID = overrideApproverUserID
    }

    public var metadata: [MetaData] {
        var entries: [MetaData] = [
            MetaData(metadataID: 0, key: "_pos_staff_user_id", value: String(staffUserID))
        ]
        if let overrideApproverUserID {
            entries.append(MetaData(metadataID: 0, key: "_pos_override_staff_user_id", value: String(overrideApproverUserID)))
        }
        return entries
    }
}
