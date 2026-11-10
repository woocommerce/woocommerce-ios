import SwiftUI
import WooFoundation

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
            .posPadding(.horizontal, \.medium)
    } buttons: {
        Button("Retry") {}
            .buttonStyle(POSFilledButtonStyle(size: .normal))
    }
}
#endif
