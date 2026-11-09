import SwiftUI
import WooFoundation

/// Layout for POS status, empty and error screens.
///
/// The buttons are pinned to the bottom and the message is centered in the space above them.
/// When the message is taller than that space it scrolls, and the buttons stay in place.
struct POSStatusScreenLayout<Message: View, Buttons: View>: View {
    @Environment(\.posMetrics) private var metrics
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.floatingControlAreaSize) private var floatingControlAreaSize: CGSize
    @Environment(\.keyboardObserver) private var keyboard

    private let message: Message
    private let buttons: Buttons

    init(@ViewBuilder message: () -> Message, @ViewBuilder buttons: () -> Buttons) {
        self.message = message()
        self.buttons = buttons()
    }

    var body: some View {
        VStack(spacing: metrics.spacing.none) {
            VStack(spacing: metrics.spacing.none) {
                Spacer(minLength: metrics.spacing.none)
                message
                Spacer(minLength: metrics.spacing.none)
            }
            .frame(maxWidth: .infinity)
            .padding(metrics.padding.medium)
            .scrollVerticallyIfNeeded()

            buttons
                .posStatusButtonsWidth()
                .padding(.bottom, metrics.padding.medium)
        }
        .padding(.bottom, floatingControlBottomPadding)
    }

    /// Keeps the buttons above the floating reader and menu controls.
    /// Phone layout never shows those controls, but the environment still carries their offset there.
    private var floatingControlBottomPadding: CGFloat {
        guard horizontalSizeClass != .compact, !keyboard.isFullSizeKeyboardVisible else {
            return metrics.padding.none
        }
        return floatingControlAreaSize.height
    }
}

#if DEBUG
#Preview("Short message") {
    POSStatusScreenLayout {
        Text("Unable to load coupons")
            .font(.posHeadingBold)
    } buttons: {
        Button("Retry") {}
            .buttonStyle(POSFilledButtonStyle(size: .normal))
    }
}

#Preview("Long message") {
    POSStatusScreenLayout {
        Text(String(repeating: "A long message that does not fit on the screen. ", count: 60))
            .font(.posBodyLargeRegular())
            .padding(.horizontal)
    } buttons: {
        Button("Retry") {}
            .buttonStyle(POSFilledButtonStyle(size: .normal))
    }
}
#endif
