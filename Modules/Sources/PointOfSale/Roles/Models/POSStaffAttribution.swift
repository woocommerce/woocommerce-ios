import struct Yosemite.POSStaffAuth

/// Builds the `POSStaffAuth` request headers for a POS action from the staff members involved,
/// centralizing the actor/initiator rules so each surface doesn't hand-roll them.
///
/// These take a non-optional operator: attribution only exists once an operator is signed in (POS
/// roles enabled). Callers map their optional operator through these, so a missing operator yields no
/// attribution at all — matching pre-roll-out behaviour.
enum POSStaffAttribution {
    /// Attribution credited solely to the operator. Used when the operator acts under their own
    /// capability, and for actions where a manager override is a *local gate only* and the approver
    /// is never recorded (e.g. coupon creation). Actor = operator.
    static func operatorOnly(_ operatorStaff: POSStaff) -> POSStaffAuth {
        POSStaffAuth(actorUserID: operatorStaff.userID)
    }

    /// Attribution for an override-capable action (e.g. refunds). When `approver` is non-nil the
    /// approving manager is the actor and the operator the initiator; otherwise the operator is the
    /// actor.
    static func authorized(operator operatorStaff: POSStaff, approver: POSStaff?) -> POSStaffAuth {
        if let approverUserID = approver?.userID {
            return POSStaffAuth(actorUserID: approverUserID, initiatorUserID: operatorStaff.userID)
        }
        return POSStaffAuth(actorUserID: operatorStaff.userID)
    }
}
