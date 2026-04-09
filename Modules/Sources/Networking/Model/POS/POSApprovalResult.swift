import Foundation

/// Response from POST /wc/v3/pos/auth/approve
/// Networking-layer model for manager approval results.
public struct POSApprovalResult: Decodable {
    public let approved: Bool
    public let approverID: Int64
    public let approverName: String
    public let approvalToken: String
    public let expiresIn: Int

    private enum CodingKeys: String, CodingKey {
        case approved
        case approverID = "approver_id"
        case approverName = "approver_name"
        case approvalToken = "approval_token"
        case expiresIn = "expires_in"
    }

    public init(approved: Bool,
                approverID: Int64,
                approverName: String,
                approvalToken: String,
                expiresIn: Int) {
        self.approved = approved
        self.approverID = approverID
        self.approverName = approverName
        self.approvalToken = approvalToken
        self.expiresIn = expiresIn
    }
}
