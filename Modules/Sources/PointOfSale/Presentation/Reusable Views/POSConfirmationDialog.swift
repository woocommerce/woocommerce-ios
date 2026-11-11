import SwiftUI

/// Content of a POS modal that asks a question: a title, a message, two buttons and an optional lower-emphasis action.
/// Present it with `posModal(..., compactStyle: .dialog)` so it is a centered card on phone.
struct POSConfirmationDialog: View {
    @Environment(\.posMetrics) private var metrics
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let title: String
    let message: String
    let primaryButton: PointOfSaleFlowButtonConfiguration.ButtonConfig
    let secondaryButton: PointOfSaleFlowButtonConfiguration.ButtonConfig
    var tertiaryButton: PointOfSaleFlowButtonConfiguration.ButtonConfig? = nil

    var body: some View {
        VStack(spacing: metrics.spacing.xLarge) {
            VStack(spacing: metrics.spacing.small) {
                Text(title)
                    .font(.posHeadingBold)
                    .accessibilityAddTraits(.isHeader)
                Text(message)
                    .font(.posBodyLargeRegular())
            }
            .foregroundStyle(Color.posOnSurface)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: metrics.spacing.small) {
                POSFlowButtonsView(configuration: .init(primaryButton: primaryButton, secondaryButton: secondaryButton))

                if let tertiaryButton {
                    Button(action: tertiaryButton.action) {
                        Text(tertiaryButton.title)
                            .font(.posBodyLargeBold)
                            .foregroundStyle(Color.posPrimary)
                            .padding(.vertical, metrics.padding.medium)
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(metrics.padding.xLarge)
        // A centered card at regular width would otherwise stretch across the whole screen.
        .frame(maxWidth: horizontalSizeClass == .regular ? Constants.regularMaxWidth : nil)
    }
}

private extension POSConfirmationDialog {
    enum Constants {
        static let regularMaxWidth: CGFloat = 560
    }
}

#if DEBUG
#Preview("Compact") {
    POSConfirmationDialog(title: "Exit Point of Sale mode?",
                          message: "Any orders in progress will be lost.",
                          primaryButton: .init(title: "Exit", action: {}),
                          secondaryButton: .init(title: "Cancel", action: {}))
    .environment(\.horizontalSizeClass, .compact)
}

#Preview("Compact, three actions") {
    POSConfirmationDialog(title: "Can't reach your printer",
                          message: "Make sure your printer is on and nearby with Bluetooth turned on, then try again.",
                          primaryButton: .init(title: "Retry", action: {}),
                          secondaryButton: .init(title: "Email receipt", action: {}),
                          tertiaryButton: .init(title: "Cancel", action: {}))
    .environment(\.horizontalSizeClass, .compact)
}

#Preview("Regular") {
    POSConfirmationDialog(title: "Exit Point of Sale mode?",
                          message: "Any orders in progress will be lost.",
                          primaryButton: .init(title: "Exit", action: {}),
                          secondaryButton: .init(title: "Cancel", action: {}))
    .environment(\.horizontalSizeClass, .regular)
}
#endif
