import Foundation
import Yosemite

extension WCPayCardBrand {
    /// A displayable brand name and last 4 digits for a card, e.g. "•••• 4242 (Visa)".
    /// The brand name comes from `displayName` (Yosemite), which is the single source of truth.
    func refundCardDescription(last4: String) -> String {
        let maskedNumber = String(format: "•••• %1$@", last4)
        guard displayName.isEmpty == false else {
            return maskedNumber
        }
        return "\(maskedNumber) (\(displayName))"
    }
}
