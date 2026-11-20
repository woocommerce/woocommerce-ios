import Foundation

/// Empty and error states shrink their illustration while the full-size keyboard is up,
/// so the message keeps room above the keyboard on short screens such as iPad in landscape.
enum POSStatusIllustrationHelper {
    static func illustrationSize(isFullSizeKeyboardVisible: Bool) -> CGFloat {
        isFullSizeKeyboardVisible ? Constants.compactIllustrationSize : Constants.regularIllustrationSize
    }

    static func errorMarkSize(isFullSizeKeyboardVisible: Bool) -> POSErrorAndAlertIconSize {
        isFullSizeKeyboardVisible ? .largeCompact : .large
    }
}

private extension POSStatusIllustrationHelper {
    enum Constants {
        static let regularIllustrationSize: CGFloat = 88
        static let compactIllustrationSize: CGFloat = 66
    }
}
