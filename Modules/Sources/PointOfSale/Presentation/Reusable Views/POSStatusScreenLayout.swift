import SwiftUI
import WooFoundation

struct POSStatusScreenLayout<Message: View, Buttons: View>: View {
    @Environment(\.posMetrics) private var metrics
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.floatingControlAreaSize) private var floatingControlAreaSize: CGSize
    @Environment(\.keyboardObserver) private var keyboard

    private let buttonsWidth: POSStatusButtonsWidth
    private let message: Message
    private let buttons: Buttons

    init(buttonsWidth: POSStatusButtonsWidth, @ViewBuilder message: () -> Message, @ViewBuilder buttons: () -> Buttons) {
        self.buttonsWidth = buttonsWidth
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
            // Search dismisses the keyboard on scroll. A message taller than the space above the keyboard
            // must stay scrollable while the merchant is still typing.
            .scrollDismissesKeyboard(.never)
            // The scroll wrapper can draw beyond its bounds at large text sizes in short windows.
            .clipped()

            sizedButtons
                .posFooterBottomPadding()
        }
        .padding(.bottom, floatingControlBottomPadding)
    }

    @ViewBuilder
    private var sizedButtons: some View {
        switch buttonsWidth {
        case .capped:
            buttons
                .posStatusButtonsWidth()
        case .fullWidth:
            buttons
                .frame(maxWidth: .infinity)
                .posContentPadding(.horizontal, metrics.padding.medium)
        }
    }

    private var floatingControlBottomPadding: CGFloat {
        guard horizontalSizeClass != .compact, !keyboard.isFullSizeKeyboardVisible else {
            return metrics.padding.none
        }
        return floatingControlAreaSize.height
    }
}

#if DEBUG
#Preview("Short message") {
    POSStatusScreenLayout(buttonsWidth: .capped) {
        Text("Unable to load coupons")
            .font(.posHeadingBold)
    } buttons: {
        Button("Retry") {}
            .buttonStyle(POSFilledButtonStyle(size: .normal))
    }
}

#Preview("Long message") {
    POSStatusScreenLayout(buttonsWidth: .capped) {
        Text(String(repeating: "A long message that does not fit on the screen. ", count: 60))
            .font(.posBodyLargeRegular())
            .posPadding(.horizontal, \.medium)
    } buttons: {
        Button("Retry") {}
            .buttonStyle(POSFilledButtonStyle(size: .normal))
    }
}
#endif
