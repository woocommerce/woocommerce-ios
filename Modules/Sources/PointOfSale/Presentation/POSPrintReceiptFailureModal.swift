import SwiftUI

/// Tells the merchant why a receipt didn't print and offers Retry or Email receipt.
struct POSPrintReceiptFailureModal: View {
    let failure: POSPrintReceiptFailure
    let selectAction: (POSPrintReceiptFailureAction) -> Void
    let close: () -> Void
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        content
            .posModalCloseButton(action: close)
            .posModalSizing(fullScreenWhenCompact: true)
            .dynamicTypeSize(...maximumDynamicTypeSize)
    }

    /// Phones cap text at the payment success screen's size so the message and buttons fit; iPad keeps full scaling.
    private var maximumDynamicTypeSize: DynamicTypeSize {
        horizontalSizeClass == .compact ? .accessibility1 : .accessibility5
    }

    /// On the full-screen phone modal, a message taller than the screen scrolls above the buttons
    /// instead of being cut to a single line.
    @ViewBuilder
    private var content: some View {
        if horizontalSizeClass == .compact {
            ViewThatFits(in: .vertical) {
                centeredContent
                scrollingContent
            }
        } else {
            centeredContent
        }
    }

    private var centeredContent: some View {
        VStack(spacing: POSSpacing.xLarge) {
            Spacer()
            failureMessage
            Spacer()
            buttons
        }
    }

    private var scrollingContent: some View {
        VStack(spacing: POSSpacing.xLarge) {
            ScrollView(showsIndicators: false) {
                failureMessage
                    .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize, axes: [.vertical])

            buttons
        }
    }

    private var failureMessage: some View {
        VStack(spacing: POSSpacing.xLarge) {
            POSErrorExclamationMark(size: .large)

            VStack(spacing: POSSpacing.small) {
                Text(failure.title)
                    .font(.posHeadingBold)
                    .foregroundStyle(Color.posOnSurface)
                    .accessibilityAddTraits(.isHeader)

                Text(failure.message)
                    .font(.posBodyLargeRegular())
                    .foregroundStyle(Color.posOnSurface)
            }
            .multilineTextAlignment(.center)
        }
    }

    private var buttons: some View {
        POSFlowButtonsView(configuration: .init(
            primaryButton: .init(title: Localization.retryButton, action: { selectAction(.retry) }),
            secondaryButton: .init(title: Localization.emailButton, action: { selectAction(.emailReceipt) })))
    }
}

private extension POSPrintReceiptFailureModal {
    enum Localization {
        static let retryButton = NSLocalizedString(
            "pos.printReceiptFailure.retryButton",
            value: "Retry",
            comment: "Button to print the receipt again from the POS print failure modal.")

        static let emailButton = NSLocalizedString(
            "pos.printReceiptFailure.emailButton",
            value: "Email receipt",
            comment: "Button to email the receipt instead of printing it, from the POS print failure modal.")
    }
}

#if DEBUG
#Preview("Paper empty") {
    POSPrintReceiptFailureModal(failure: .paperEmpty, selectAction: { _ in }, close: {})
        .posPreviewModalParentSize()
}

#Preview("Printer offline") {
    POSPrintReceiptFailureModal(failure: .printerOffline, selectAction: { _ in }, close: {})
        .posPreviewModalParentSize()
}

#Preview("iPhone SE: Printer offline", traits: .sizeThatFitsLayout) {
    POSPrintReceiptFailureModal(failure: .printerOffline, selectAction: { _ in }, close: {})
        .posPreviewSmallestPhone()
}
#endif
