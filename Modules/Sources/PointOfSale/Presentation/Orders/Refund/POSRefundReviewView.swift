import SwiftUI

struct POSRefundReviewView: View {
    let onClose: () -> Void
    let itemsCount: Int
    let formattedItemsSubtotal: String
    let formattedTax: String
    let formattedRefundTotal: String
    let paymentMethodDescription: String
    let refundReason: String?
    let onAddReason: () -> Void
    let onContinue: () -> Void

    @Environment(\.posModalParentSize) private var parentSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        VStack(spacing: POSSpacing.none) {
            headerView
            summarySection
            Spacer(minLength: POSSpacing.large)
            buttonsSection
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.posSurfaceBright)
        .posRefundModalFrame(parentSize: parentSize, horizontalSizeClass: horizontalSizeClass)
        .posEdgeSwipeBackAction(onBack: onClose)
    }
}

// MARK: - Subviews

private extension POSRefundReviewView {
    var headerView: some View {
        POSRefundNavigationHeader(title: Localization.title,
                                  backAction: nil,
                                  backAccessibilityLabel: Localization.backButtonAccessibilityLabel)
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
        .frame(maxWidth: .infinity)
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
                    Text(refundReason != nil ? Localization.editReasonButton : Localization.addReasonButton)
                        .font(.posBodyMediumRegular(underline: true))
                        .foregroundColor(Color.posLink)
                }
                .accessibilityLabel(refundReason != nil ? Localization.editReasonAccessibilityLabel : Localization.addReasonAccessibilityLabel)
            }
            Text(refundReason ?? Localization.reasonPlaceholder)
                .font(.posBodyMediumRegular())
                .foregroundColor(refundReason != nil ? .posOnSurfaceVariantHighest : .posOnSurfaceVariantLowest)
        }
    }

    var buttonsSection: some View {
        VStack(spacing: POSSpacing.medium) {
            Button(Localization.continueButton, action: onContinue)
                .buttonStyle(POSFilledButtonStyle(size: .normal))

            Button(Localization.backButton, action: onClose)
                .buttonStyle(POSOutlinedButtonStyle(size: .normal))
        }
        .posPhoneFullScreenButtonPadding(horizontalSizeClass: horizontalSizeClass,
                                         maxWidth: .infinity)
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

// MARK: - Localization

private extension POSRefundReviewView {
    enum Localization {
        static let title = NSLocalizedString(
            "pos.refundReviewView.title",
            value: "Review refund",
            comment: "Title for the refund review modal"
        )

        static let backButtonAccessibilityLabel = NSLocalizedString(
            "pos.refundReviewView.backButton.accessibilityLabel",
            value: "Back",
            comment: "Accessibility label for the back button on the refund review screen"
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

        static let editReasonButton = NSLocalizedString(
            "pos.refundReviewView.editReasonButton",
            value: "Edit reason",
            comment: "Button to edit an existing refund reason"
        )

        static let addReasonAccessibilityLabel = NSLocalizedString(
            "pos.refundReviewView.addReason.accessibilityLabel",
            value: "Add refund reason",
            comment: "Accessibility label for add reason button in refund review"
        )

        static let editReasonAccessibilityLabel = NSLocalizedString(
            "pos.refundReviewView.editReason.accessibilityLabel",
            value: "Edit refund reason",
            comment: "Accessibility label for edit reason button in refund review"
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

        static let backButton = NSLocalizedString(
            "pos.refundReviewView.backButton",
            value: "Back",
            comment: "Button to go back from the refund review screen to refund item selection"
        )
    }
}

#if DEBUG
#Preview("POSRefundReviewView") {
    POSRefundReviewView(
        onClose: { },
        itemsCount: 6,
        formattedItemsSubtotal: "$110.50",
        formattedTax: "$22.10",
        formattedRefundTotal: "$132.60",
        paymentMethodDescription: "Via payment card ••••1456",
        refundReason: nil,
        onAddReason: {},
        onContinue: {}
    )
    .environment(\.posModalParentSize, CGSize(width: 1192, height: 822))
}

#Preview("POSRefundReviewView with reason") {
    POSRefundReviewView(
        onClose: { },
        itemsCount: 3,
        formattedItemsSubtotal: "$45.00",
        formattedTax: "$4.50",
        formattedRefundTotal: "$49.50",
        paymentMethodDescription: "Via cash",
        refundReason: "Customer changed their mind",
        onAddReason: {},
        onContinue: {}
    )
    .environment(\.posModalParentSize, CGSize(width: 1192, height: 822))
}
#endif
