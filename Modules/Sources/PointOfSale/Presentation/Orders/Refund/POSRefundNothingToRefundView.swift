import SwiftUI

struct POSRefundNothingToRefundView: View {
    let onClose: () -> Void

    @Environment(\.posModalParentSize) private var parentSize

    var body: some View {
        VStack(spacing: POSSpacing.none) {
            headerView
            contentView
            buttonsSection
        }
        .background(Color.posSurfaceBright)
        .clipShape(RoundedRectangle(cornerRadius: POSRefundModalLayout.cornerRadius))
        .frame(width: parentSize.width - (POSRefundModalLayout.horizontalPadding * 2))
    }
}

// MARK: - Subviews

private extension POSRefundNothingToRefundView {
    var headerView: some View {
        HStack {
            Text(Localization.title)
                .font(.posHeadingBold)
                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                .lineLimit(1)
            Spacer()
            Button {
                onClose()
            } label: {
                Text(Image(systemName: "xmark"))
                    .font(.posButtonSymbolLarge)
            }
            .accessibilityLabel(Localization.closeButtonAccessibilityLabel)
        }
        .foregroundColor(Color.posOnSurface)
        .padding(POSPadding.xLarge)
    }

    var contentView: some View {
        Text(Localization.message)
            .font(.posBodyLargeRegular())
            .foregroundColor(Color.posOnSurface)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, POSPadding.xLarge)
    }

    var buttonsSection: some View {
        Button(Localization.doneButton, action: onClose)
            .buttonStyle(POSFilledButtonStyle(size: .normal))
            .padding(POSPadding.xLarge)
    }
}

// MARK: - Localization

private extension POSRefundNothingToRefundView {
    enum Localization {
        static let title = NSLocalizedString(
            "pos.refundNothingToRefundView.title",
            value: "Nothing to refund",
            comment: "Title shown when there are no items available to refund"
        )

        static let closeButtonAccessibilityLabel = NSLocalizedString(
            "pos.refundNothingToRefundView.closeButton.accessibilityLabel",
            value: "Close",
            comment: "Accessibility label for close button on nothing to refund modal"
        )

        static let message = NSLocalizedString(
            "pos.refundNothingToRefundView.message",
            value: "All items in this order have already been refunded.",
            comment: "Message explaining why there are no items to refund"
        )

        static let doneButton = NSLocalizedString(
            "pos.refundNothingToRefundView.doneButton",
            value: "Done",
            comment: "Button to dismiss the nothing to refund screen"
        )
    }
}

#if DEBUG
#Preview("POSRefundNothingToRefundView") {
    POSRefundNothingToRefundView(
        onClose: {}
    )
    .environment(\.posModalParentSize, CGSize(width: 1192, height: 822))
}
#endif
