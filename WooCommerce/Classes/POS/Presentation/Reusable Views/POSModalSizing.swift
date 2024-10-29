import SwiftUI

extension View {
    /// Sets the frame size and applies a padding to a modal in POS.
    func posModalSizing() -> some View {
        self.modifier(POSModalSizing())
    }
}

struct POSModalSizing: ViewModifier {
    @Environment(\.sizeCategory) private var sizeCategory

    func body(content: Content) -> some View {
        content
            .padding(PointOfSaleReaderConnectionModalLayout.contentPadding)
            .frame(width: frameWidth, height: frameHeight)
    }
}

private extension POSModalSizing {
    var frameWidth: CGFloat {
        switch sizeCategory {
        case .extraSmall, .small:
            return 560
        case .medium, .large, .extraLarge:
            return 640
        case .extraExtraLarge, .extraExtraExtraLarge:
            return 720
        case .accessibilityMedium,
                .accessibilityLarge,
                .accessibilityExtraLarge,
                .accessibilityExtraExtraLarge,
                .accessibilityExtraExtraExtraLarge:
            return windowBounds.width
        @unknown default:
            return 640
        }
    }

    var frameHeight: CGFloat {
        switch sizeCategory {
        case .extraSmall, .small:
            return 624
        case .medium, .large, .extraLarge:
            return 656
        case .extraExtraLarge, .extraExtraExtraLarge:
            return 688
        case .accessibilityMedium,
                .accessibilityLarge,
                .accessibilityExtraLarge,
                .accessibilityExtraExtraLarge,
                .accessibilityExtraExtraExtraLarge:
            return windowBounds.height
        @unknown default:
            return 656
        }
    }

    var windowBounds: CGRect {
        window?.bounds ?? UIScreen.main.bounds
    }

    var window: UIWindow? {
        UIApplication
            .shared
            .connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .last
    }
}

private extension POSModalSizing {
    enum Localization {
        static let defaultAccessibilityLabel = NSLocalizedString(
            "pointOfSale.cardPresentPayment.connection.modal.close.button.accessibilityLabel.default",
            value: "Close",
            comment: "The default accessibility label for an `x` close button on a card reader connection modal.")
    }
}
