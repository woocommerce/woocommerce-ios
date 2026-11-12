import SwiftUI

/// Content of a POS modal that asks a question: a close button in the top corner, a title, a message and the buttons.
/// Present it with `posModal(..., compactStyle: .dialog)` so phone shows the same centered card as iPad.
struct POSConfirmationDialog: View {
    @Environment(\.posMetrics) private var metrics
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let title: String
    let message: String
    let primaryButton: PointOfSaleFlowButtonConfiguration.ButtonConfig
    let secondaryButton: PointOfSaleFlowButtonConfiguration.ButtonConfig?
    let closeButton: CloseButton

    struct CloseButton {
        let accessibilityLabel: String
        let accessibilityIdentifier: String?
        let action: () -> Void
    }

    init(title: String,
         message: String,
         primaryButton: PointOfSaleFlowButtonConfiguration.ButtonConfig,
         secondaryButton: PointOfSaleFlowButtonConfiguration.ButtonConfig? = nil,
         closeButton: CloseButton) {
        self.title = title
        self.message = message
        self.primaryButton = primaryButton
        self.secondaryButton = secondaryButton
        self.closeButton = closeButton
    }

    var body: some View {
        VStack(spacing: metrics.spacing.xLarge) {
            POSModalCloseButton(accessibilityLabel: closeButton.accessibilityLabel,
                                accessibilityIdentifier: closeButton.accessibilityIdentifier,
                                fontStyle: horizontalSizeClass == .compact ? .posButtonSymbolMedium : .posButtonSymbolLarge,
                                closeAction: closeButton.action)

            VStack(spacing: metrics.spacing.xLarge) {
                Text(title)
                    .font(.posHeadingBold)
                    .accessibilityAddTraits(.isHeader)
                Text(message)
                    .font(.posBodyLargeRegular())
            }
            .foregroundStyle(Color.posOnSurface)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)

            POSFlowButtonsView(configuration: .init(primaryButton: primaryButton, secondaryButton: secondaryButton))
        }
        .padding(metrics.padding.medium)
    }
}

#if DEBUG
#Preview("Compact") {
    POSConfirmationDialog(title: "Exit Point of Sale mode?",
                          message: "Any orders in progress will be lost.",
                          primaryButton: .init(title: "Exit", action: {}),
                          closeButton: .init(accessibilityLabel: "Close", accessibilityIdentifier: nil, action: {}))
    .environment(\.horizontalSizeClass, .compact)
}

#Preview("Regular") {
    POSConfirmationDialog(title: "Exit Point of Sale mode?",
                          message: "Any orders in progress will be lost.",
                          primaryButton: .init(title: "Exit", action: {}),
                          closeButton: .init(accessibilityLabel: "Close", accessibilityIdentifier: nil, action: {}))
    .environment(\.horizontalSizeClass, .regular)
}
#endif
