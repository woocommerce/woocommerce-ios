import SwiftUI

struct POSRefundReaderDisconnectedView: View {
    @Environment(\.posMetrics) private var metrics
    let onConnect: () -> Void
    let onCancel: () -> Void
    let onBack: () -> Void

    @Environment(\.posModalParentSize) private var parentSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Namespace private var paymentMessageNamespace

    var body: some View {
        ZStack(alignment: .topLeading) {
            POSStatusScreenLayout(buttonsWidth: .capped) {
                PointOfSaleCardPresentPaymentReaderDisconnectedMessageView(
                    viewModel: .init(
                        title: Localization.title,
                        connectReaderButtonTitle: Localization.connectButton,
                        instruction: Localization.instruction
                    ),
                    animation: .init(namespace: paymentMessageNamespace)
                )
            } buttons: {
                buttonsSection
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            headerView
        }
        .background(Color.posSurfaceBright)
        .posRefundModalFrame(parentSize: parentSize, horizontalSizeClass: horizontalSizeClass)
        .posEdgeSwipeBackAction(onBack: onBack)
    }
}

private extension POSRefundReaderDisconnectedView {
    @ViewBuilder
    var headerView: some View {
        if horizontalSizeClass == .compact {
            POSRefundNavigationHeader(backAction: onBack,
                                      backAccessibilityLabel: Localization.backButtonAccessibilityLabel)
        } else {
            regularHeaderView
        }
    }

    var regularHeaderView: some View {
        HStack {
            Button(action: onBack) {
                Text(Image(systemName: "chevron.backward"))
                    .font(.posButtonSymbolLarge)
            }
            .accessibilityLabel(Localization.backButtonAccessibilityLabel)

            Spacer()
        }
        .foregroundColor(Color.posOnSurface)
        .padding(metrics.padding.xLarge)
    }

    var buttonsSection: some View {
        VStack(spacing: metrics.spacing.medium) {
            Button(Localization.connectButton, action: onConnect)
                .buttonStyle(POSFilledButtonStyle(size: .normal))

            Button(Localization.cancelButton, action: onCancel)
                .buttonStyle(POSOutlinedButtonStyle(size: .normal))
        }
    }
}

private extension POSRefundReaderDisconnectedView {
    enum Localization {
        static let title = NSLocalizedString(
            "pos.refundReaderDisconnectedView.title",
            value: "Reader not connected",
            comment: "Title shown when an in-person refund needs a card reader, but no reader is connected."
        )

        static let instruction = NSLocalizedString(
            "pos.refundReaderDisconnectedView.instruction",
            value: "To process this refund, please connect your reader.",
            comment: "Instruction shown when an in-person refund needs a card reader, but no reader is connected."
        )

        static let connectButton = NSLocalizedString(
            "pos.refundReaderDisconnectedView.connectButton.title",
            value: "Connect your reader",
            comment: "Button to connect to a card reader before processing an in-person refund."
        )

        static let cancelButton = NSLocalizedString(
            "pos.refundReaderDisconnectedView.cancelButton.title",
            value: "Cancel",
            comment: "Button to cancel a refund when no card reader is connected."
        )

        static let backButtonAccessibilityLabel = NSLocalizedString(
            "pos.refundReaderDisconnectedView.backButton.accessibilityLabel",
            value: "Back",
            comment: "Accessibility label for the back button shown before connecting a card reader for a refund."
        )
    }
}

#if DEBUG
#Preview("POSRefundReaderDisconnectedView") {
    POSRefundReaderDisconnectedView(onConnect: {},
                                    onCancel: {},
                                    onBack: {})
    .posPreviewModalParentSize()
}
#endif
