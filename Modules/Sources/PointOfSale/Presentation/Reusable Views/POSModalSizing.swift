import SwiftUI

extension View {
    /// Sets the frame size and applies a padding to a modal in POS.
    func posModalSizing() -> some View {
        self.modifier(POSModalSizing())
    }
}

struct POSModalSizing: ViewModifier {
    @Environment(\.sizeCategory) private var sizeCategory
    @Environment(\.posModalParentSize) private var parentSize

    func body(content: Content) -> some View {
        content
            .padding(PointOfSaleReaderConnectionModalLayout.contentPadding)
            .frame(width: frameWidth, height: frameHeight)
    }
}

private extension POSModalSizing {
    var frameWidth: CGFloat {
        return min(preferredFrameWidth, maxAvailableFrameWidth)
    }

    var preferredFrameWidth: CGFloat {
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

    var maxAvailableFrameWidth: CGFloat {
        return parentSize.width
    }

    var frameHeight: CGFloat {
        return min(preferredFrameHeight, maxAvailableFrameHeight)
    }

    var preferredFrameHeight: CGFloat {
        switch sizeCategory {
        case .extraSmall, .small:
            return 640
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

    var maxAvailableFrameHeight: CGFloat {
        parentSize.height
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
