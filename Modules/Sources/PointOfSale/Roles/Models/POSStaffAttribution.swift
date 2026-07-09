import struct Yosemite.POSStaffAuth

/// Builds the `POSStaffAuth` request headers a POS write request carries, from the staff members
/// involved — the same shape for every endpoint, so no surface hand-rolls the actor/initiator rules.
///
/// Takes a non-optional operator: attribution only exists once an operator is signed in (POS roles
/// enabled). Callers map their optional operator through it, so a missing operator yields no
/// attribution at all — matching pre-roll-out behaviour.
enum POSStaffAttribution {
    /// When `approver` is non-nil (the action was authorized via manager override) the approving
    /// manager is the actor and the operator the initiator; otherwise the operator is the actor.
    static func authorized(operator operatorStaff: POSStaff, approver: POSStaff?) -> POSStaffAuth {
        if let approverUserID = approver?.userID {
            return POSStaffAuth(actorUserID: approverUserID, initiatorUserID: operatorStaff.userID)
        }
        return POSStaffAuth(actorUserID: operatorStaff.userID)
    }
}
