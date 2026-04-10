import Foundation

/// Response from POST /wc/v3/pos/auth/pin/manage
///
public struct POSPINManageResult: Decodable, Equatable {
    public let success: Bool

    public init(success: Bool) {
        self.success = success
    }
}
