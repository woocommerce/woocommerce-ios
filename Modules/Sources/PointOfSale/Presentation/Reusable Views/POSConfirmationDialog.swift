import SwiftUI

/// Content of a POS modal that asks a question: a title, a message and two buttons.
/// Present it with `posModal(..., compactStyle: .dialog)` so it is a centered card on phone.
struct POSConfirmationDialog: View {
    @Environment(\.posMetrics) private var metrics

    let title: String
    let message: String
    let primaryButton: PointOfSaleFlowButtonConfiguration.ButtonConfig
    let secondaryButton: PointOfSaleFlowButtonConfiguration.ButtonConfig

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

            POSFlowButtonsView(configuration: .init(primaryButton: primaryButton, secondaryButton: secondaryButton))
        }
        .padding(metrics.padding.xLarge)
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

#Preview("Regular") {
    POSConfirmationDialog(title: "Exit Point of Sale mode?",
                          message: "Any orders in progress will be lost.",
                          primaryButton: .init(title: "Exit", action: {}),
                          secondaryButton: .init(title: "Cancel", action: {}))
    .environment(\.horizontalSizeClass, .regular)
}
#endif
