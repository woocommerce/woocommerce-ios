import SwiftUI

struct POSRefundReaderDisconnectedView: View {
    let onConnect: () -> Void
    let onCancel: () -> Void
    let onBack: () -> Void

    @Environment(\.posModalParentSize) private var parentSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Namespace private var paymentMessageNamespace

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: POSSpacing.none) {
                Spacer(minLength: POSSpacing.large)

                PointOfSaleCardPresentPaymentReaderDisconnectedMessageView(
                    viewModel: .init(
                        title: Localization.title,
                        connectReaderButtonTitle: Localization.connectButton,
                        instruction: Localization.instruction
                    ),
                    animation: .init(namespace: paymentMessageNamespace)
                )

                Spacer(minLength: POSSpacing.large)

                buttonsSection
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            headerView
        }
        .background(Color.posSurfaceBright)
        .posRefundModalFrame(parentSize: parentSize, horizontalSizeClass: horizontalSizeClass)
    }
}

private extension POSRefundReaderDisconnectedView {
    var headerView: some View {
        HStack {
            Button(action: onBack) {
                Text(Image(systemName: "chevron.left"))
                    .font(.posButtonSymbolLarge)
            }
            .accessibilityLabel(Localization.backButtonAccessibilityLabel)

            Spacer()
        }
        .foregroundColor(Color.posOnSurface)
        .padding(POSPadding.xLarge)
    }

    var buttonsSection: some View {
        VStack(spacing: POSSpacing.medium) {
            Button(Localization.connectButton, action: onConnect)
                .buttonStyle(POSFilledButtonStyle(size: .normal))

            Button(Localization.cancelButton, action: onCancel)
                .buttonStyle(POSOutlinedButtonStyle(size: .normal))
        }
        .frame(maxWidth: .infinity)
        .posPhoneFullScreenButtonPadding(horizontalSizeClass: horizontalSizeClass)
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
    .environment(\.posModalParentSize, CGSize(width: 1192, height: 822))
}
#endif
