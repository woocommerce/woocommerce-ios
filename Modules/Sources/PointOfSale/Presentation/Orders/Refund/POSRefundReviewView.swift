import SwiftUI

struct POSRefundReviewView: View {
    @Binding var isPresented: Bool
    @Environment(\.posModalParentSize) private var parentSize

    let itemsCount: Int
    let formattedItemsSubtotal: String
    let formattedTax: String
    let formattedRefundTotal: String
    let paymentMethodDescription: String
    let refundReason: String?
    let onAddReason: () -> Void
    let onContinue: () -> Void
    let onEditRefund: () -> Void

    var body: some View {
        VStack(spacing: POSSpacing.none) {
            headerView
            summarySection
            buttonsSection
        }
        .background(Color.posSurfaceBright)
        .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
        .frame(width: parentSize.width - (Constants.modalHorizontalPadding * 2))
    }
}

// MARK: - Subviews

private extension POSRefundReviewView {
    var headerView: some View {
        HStack {
            Text(Localization.title)
                .font(.posHeadingBold)
                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                .lineLimit(1)
            Spacer()
            Button {
                isPresented = false
            } label: {
                Text(Image(systemName: "xmark"))
                    .font(.posButtonSymbolLarge)
            }
            .accessibilityLabel(Localization.closeButtonAccessibilityLabel)
        }
        .foregroundColor(Color.posOnSurface)
        .padding(POSPadding.xLarge)
    }

    var summarySection: some View {
        VStack(spacing: POSSpacing.medium) {
            itemsAndTaxRows
            Divider()
                .overlay(Color.posOutlineVariant.opacity(0.5))
            refundTotalSection
            Divider()
                .overlay(Color.posOutlineVariant.opacity(0.5))
            refundReasonSection
        }
        .padding(.horizontal, POSPadding.xLarge)
    }

    var itemsAndTaxRows: some View {
        VStack(spacing: POSSpacing.small) {
            summaryRow(
                label: String(format: Localization.itemsSubtotalFormat, itemsCount),
                value: formattedItemsSubtotal,
                labelColor: .posOnSurfaceVariantHighest,
                valueColor: .posOnSurface
            )
            summaryRow(
                label: Localization.taxLabel,
                value: formattedTax,
                labelColor: .posOnSurfaceVariantHighest,
                valueColor: .posOnSurface
            )
        }
    }

    var refundTotalSection: some View {
        VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
            HStack {
                Text(Localization.refundTotalLabel)
                    .font(.posBodyLargeBold)
                    .foregroundColor(.posOnSurface)
                Spacer()
                Text(formattedRefundTotal)
                    .font(.posBodyMediumRegular())
                    .foregroundColor(.posOnSurface)
            }
            Text(paymentMethodDescription)
                .font(.posBodyMediumRegular())
                .foregroundColor(.posOnSurfaceVariantHighest)
        }
    }

    var refundReasonSection: some View {
        VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
            HStack {
                Text(Localization.refundReasonLabel)
                    .font(.posBodyLargeBold)
                    .foregroundColor(.posOnSurface)
                Spacer()
                Button(action: onAddReason) {
                    Text(Localization.addReasonButton)
                        .font(.posBodyMediumRegular(underline: true))
                        .foregroundColor(.posPrimary)
                }
                .accessibilityLabel(Localization.addReasonAccessibilityLabel)
            }
            Text(refundReason ?? Localization.reasonPlaceholder)
                .font(.posBodyMediumRegular())
                .foregroundColor(.posOnSurfaceVariantHighest)
        }
    }

    var buttonsSection: some View {
        VStack(spacing: POSSpacing.medium) {
            Button(Localization.continueButton, action: onContinue)
                .buttonStyle(POSFilledButtonStyle(size: .normal))

            Button(Localization.editRefundButton, action: onEditRefund)
                .buttonStyle(POSOutlinedButtonStyle(size: .normal))
        }
        .padding(POSPadding.xLarge)
    }

    func summaryRow(label: String, value: String, labelColor: Color, valueColor: Color) -> some View {
        HStack {
            Text(label)
                .font(.posBodyMediumRegular())
                .foregroundColor(labelColor)
            Spacer()
            Text(value)
                .font(.posBodyMediumRegular())
                .foregroundColor(valueColor)
        }
    }
}

// MARK: - Constants

private extension POSRefundReviewView {
    enum Constants {
        static let modalHorizontalPadding: CGFloat = 148
        static let cornerRadius: CGFloat = 24
    }
}

// MARK: - Localization

private extension POSRefundReviewView {
    enum Localization {
        static let title = NSLocalizedString(
            "pos.refundReviewView.title",
            value: "Review refund",
            comment: "Title for the refund review modal"
        )

        static let closeButtonAccessibilityLabel = NSLocalizedString(
            "pos.refundReviewView.closeButton.accessibilityLabel",
            value: "Close",
            comment: "Accessibility label for close button on refund review modal"
        )

        static let itemsSubtotalFormat = NSLocalizedString(
            "pos.refundReviewView.itemsSubtotalFormat",
            value: "Items subtotal (%d items)",
            comment: "Label for items subtotal row in refund review. %d is the number of items."
        )

        static let taxLabel = NSLocalizedString(
            "pos.refundReviewView.taxLabel",
            value: "Tax",
            comment: "Label for tax row in refund review"
        )

        static let refundTotalLabel = NSLocalizedString(
            "pos.refundReviewView.refundTotalLabel",
            value: "Refund total",
            comment: "Label for refund total row in refund review"
        )

        static let refundReasonLabel = NSLocalizedString(
            "pos.refundReviewView.refundReasonLabel",
            value: "Refund reason",
            comment: "Label for refund reason section in refund review"
        )

        static let addReasonButton = NSLocalizedString(
            "pos.refundReviewView.addReasonButton",
            value: "Add reason",
            comment: "Button to add a reason for the refund"
        )

        static let addReasonAccessibilityLabel = NSLocalizedString(
            "pos.refundReviewView.addReason.accessibilityLabel",
            value: "Add refund reason",
            comment: "Accessibility label for add reason button in refund review"
        )

        static let reasonPlaceholder = NSLocalizedString(
            "pos.refundReviewView.reasonPlaceholder",
            value: "Reason for refunding order",
            comment: "Placeholder text when no refund reason has been added"
        )

        static let continueButton = NSLocalizedString(
            "pos.refundReviewView.continueButton",
            value: "Continue",
            comment: "Button to continue with the refund"
        )

        static let editRefundButton = NSLocalizedString(
            "pos.refundReviewView.editRefundButton",
            value: "Edit refund",
            comment: "Button to go back and edit the refund items"
        )
    }
}

#if DEBUG
#Preview("POSRefundReviewView") {
    POSRefundReviewView(
        isPresented: .constant(true),
        itemsCount: 6,
        formattedItemsSubtotal: "$110.50",
        formattedTax: "$22.10",
        formattedRefundTotal: "$132.60",
        paymentMethodDescription: "Via payment card ••••1456",
        refundReason: nil,
        onAddReason: {},
        onContinue: {},
        onEditRefund: {}
    )
    .environment(\.posModalParentSize, CGSize(width: 1192, height: 822))
}

#Preview("POSRefundReviewView with reason") {
    POSRefundReviewView(
        isPresented: .constant(true),
        itemsCount: 3,
        formattedItemsSubtotal: "$45.00",
        formattedTax: "$4.50",
        formattedRefundTotal: "$49.50",
        paymentMethodDescription: "Via cash",
        refundReason: "Customer changed their mind",
        onAddReason: {},
        onContinue: {},
        onEditRefund: {}
    )
    .environment(\.posModalParentSize, CGSize(width: 1192, height: 822))
}
#endif
