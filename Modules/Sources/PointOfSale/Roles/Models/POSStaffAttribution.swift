import struct Yosemite.POSStaffAuth

/// Builds the `POSStaffAuth` request headers for a gated POS action from the staff members involved,
/// centralizing the two attribution shapes so each action surface doesn't hand-roll the
/// actor/initiator rules.
///
/// Both factories return `nil` when no operator is signed in, so the network boundary sends no POS
/// headers — matching pre-roll-out behaviour.
enum POSStaffAttribution {
    /// Attribution credited solely to the operator. Used when the operator acts under their own
    /// capability, and for actions where a manager override is a *local gate only* and the approver
    /// is never recorded (e.g. coupon creation). Actor = operator.
    static func operatorOnly(_ operatorStaff: POSStaff?) -> POSStaffAuth? {
        guard let operatorUserID = operatorStaff?.userID else {
            return nil
        }
        return POSStaffAuth(actorUserID: operatorUserID)
    }

    /// Attribution for an override-capable action (e.g. refunds). When `approver` is non-nil the
    /// approving manager is the actor and the operator is the initiator; otherwise the operator is
    /// the actor.
    static func authorized(operator operatorStaff: POSStaff?, approver: POSStaff?) -> POSStaffAuth? {
        guard let operatorUserID = operatorStaff?.userID else {
            return nil
        }
        if let approverUserID = approver?.userID {
            return POSStaffAuth(actorUserID: approverUserID, initiatorUserID: operatorUserID)
        }
        return POSStaffAuth(actorUserID: operatorUserID)
    }
}
