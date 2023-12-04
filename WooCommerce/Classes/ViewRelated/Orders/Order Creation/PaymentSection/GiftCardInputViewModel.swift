import Foundation
import Yosemite

/// View model for `GiftCardInputView`.
final class GiftCardInputViewModel: ObservableObject {
    @Published var code: String
    @Published private(set) var isValid: Bool = false
    @Published private(set) var errorMessage: String?

    private let setGiftCard: (_ code: String?) -> Void
    private let dismiss: () -> Void

    init(code: String, setGiftCard: @escaping (_ code: String?) -> Void, dismiss: @escaping () -> Void) {
        self.code = code
        self.setGiftCard = setGiftCard
        self.dismiss = dismiss
        observeCodeForValidCheck()
    }

    /// Applies the gift card code to the order.
    func apply() {
        setGiftCard(code)
    }

    /// Removes the gift card code from the order.
    func remove() {
        setGiftCard(nil)
    }

    /// Cancels the gift card input form.
    func cancel() {
        dismiss()
    }
}

extension GiftCardInputViewModel {
    static func isCodeValid(_ code: String) -> Bool {
        let format = "^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$"

        let regex = try? NSRegularExpression(pattern: format, options: .caseInsensitive)
        let range = NSRange(location: 0, length: code.count)

        return regex?.firstMatch(in: code, options: [], range: range) != nil
    }
}

private extension GiftCardInputViewModel {
    func observeCodeForValidCheck() {
        $code.removeDuplicates()
            .map { Self.isCodeValid($0) }
            .assign(to: &$isValid)

        $isValid.combineLatest($code)
            .map { isValid, code in
                isValid || code.isEmpty ? nil: Localization.errorMessage
            }
            .assign(to: &$errorMessage)
    }
}

private extension GiftCardInputViewModel {
    enum Localization {
        static let errorMessage = NSLocalizedString(
            "The code should be in XXXX-XXXX-XXXX-XXXX format",
            comment: "Message in the gift card input form when the code is not valid."
        )
    }
}
