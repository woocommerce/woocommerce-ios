import Foundation

/// Information required for a gift card item during checkout.
/// This data is sent with the `add-item` API call using:
/// - `wc_gc_giftcard_to`: recipientEmail
/// - `wc_gc_giftcard_from`: senderName
struct GiftCardInfo: Equatable {
    let recipientEmail: String
    let senderName: String
}
