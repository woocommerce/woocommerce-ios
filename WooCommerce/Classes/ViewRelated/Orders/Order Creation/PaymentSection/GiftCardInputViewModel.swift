import Foundation
import Yosemite

/// View model for `GiftCardInputView`.
final class GiftCardInputViewModel: ObservableObject {
    @Published var code: String

    private let addGiftCard: (_ code: String) -> Void
    private let dismiss: () -> Void

    init(code: String, addGiftCard: @escaping (_ code: String) -> Void, dismiss: @escaping () -> Void) {
        self.code = code
        self.addGiftCard = addGiftCard
        self.dismiss = dismiss
    }

    /// Applies the gift card code to the order.
    func apply() {
        addGiftCard(code)
    }

    /// Cancels the gift card input form.
    func cancel() {
        dismiss()
    }
}
