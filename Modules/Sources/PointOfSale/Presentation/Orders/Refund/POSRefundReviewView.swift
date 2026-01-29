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
    let onEditRefund: () -> Void

    @Environment(\.posModalParentSize) private var parentSize

    var body: some View {
        VStack(spacing: POSSpacing.none) {
            headerView
            summarySection
            buttonsSection
        }
        .background(Color.posSurfaceBright)
        .clipShape(RoundedRectangle(cornerRadius: POSRefundModalLayout.cornerRadius))
        .frame(width: parentSize.width - (POSRefundModalLayout.horizontalPadding * 2))
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
                    Text(refundReason != nil ? Localization.editReasonButton : Localization.addReasonButton)
                        .font(.posBodyMediumRegular(underline: true))
                        .foregroundColor(.posPrimary)
                }
                .accessibilityLabel(refundReason != nil ? Localization.editReasonAccessibilityLabel : Localization.addReasonAccessibilityLabel)
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

// MARK: - Localization

private extension POSRefundReviewView {
    enum Localization {
        static let title = NSLocalizedString(
            "pos.refundReviewView.title",
            value: "Review refund",
            comment: "This text appears as the title of a modal screen in the Point of Sale app where merchants review details of a refund before processing it. It's displayed as a header at the top of the refund review interface."
        )

        static let closeButtonAccessibilityLabel = NSLocalizedString(
            "pos.refundReviewView.closeButton.accessibilityLabel",
            value: "Close",
            comment: "This is the accessibility label for a close button on the refund review modal in the point-of-sale system. Screen readers will announce this text when users focus on the button that dismisses the refund review screen."
        )

        static let itemsSubtotalFormat = NSLocalizedString(
            "pos.refundReviewView.itemsSubtotalFormat",
            value: "Items subtotal (%d items)",
            comment: "Label for items subtotal row in refund review. %d is the number of items."
        )

        static let taxLabel = NSLocalizedString(
            "pos.refundReviewView.taxLabel",
            value: "Tax",
            comment: "A label displayed in the refund review screen of the Point of Sale module, identifying the tax amount line item in the refund breakdown summary."
        )

        static let refundTotalLabel = NSLocalizedString(
            "pos.refundReviewView.refundTotalLabel",
            value: "Refund total",
            comment: "A label that displays the total amount to be refunded to the customer on the refund review screen in a point-of-sale app. This appears as a row label in a summary breakdown showing the final refund amount before processing the transaction."
        )

        static let refundReasonLabel = NSLocalizedString(
            "pos.refundReviewView.refundReasonLabel",
            value: "Refund reason",
            comment: "This is a section label that appears in the refund review screen of a point-of-sale app, identifying the area where users can view or add the reason for processing a refund."
        )

        static let addReasonButton = NSLocalizedString(
            "pos.refundReviewView.addReasonButton",
            value: "Add reason",
            comment: "Button label that appears in the refund review screen of a point-of-sale app, allowing users to add an optional reason/explanation for why they are processing a refund."
        )

        static let editReasonButton = NSLocalizedString(
            "pos.refundReviewView.editReasonButton",
            value: "Edit reason",
            comment: "Button text that appears in the refund review screen of the Point of Sale app, allowing users to modify a refund reason that has already been entered. This button is displayed when a refund reason already exists and needs to be changed."
        )

        static let addReasonAccessibilityLabel = NSLocalizedString(
            "pos.refundReviewView.addReason.accessibilityLabel",
            value: "Add refund reason",
            comment: "Accessibility label for a button that allows users to add a reason when processing refunds in the Point of Sale interface. This text is read by screen readers when users with accessibility needs interact with the add reason button during the refund review process."
        )

        static let editReasonAccessibilityLabel = NSLocalizedString(
            "pos.refundReviewView.editReason.accessibilityLabel",
            value: "Edit refund reason",
            comment: "This is an accessibility label for a button in the refund review screen that allows users to edit an existing refund reason. The label is read by screen readers to help visually impaired users understand the purpose of the edit button."
        )

        static let reasonPlaceholder = NSLocalizedString(
            "pos.refundReviewView.reasonPlaceholder",
            value: "Reason for refunding order",
            comment: "This text appears as placeholder text in a text input field on the refund review screen, prompting users to enter a reason for refunding an order. It displays when no refund reason has been entered yet and guides users on what information to provide."
        )

        static let continueButton = NSLocalizedString(
            "pos.refundReviewView.continueButton",
            value: "Continue",
            comment: "Button label in the Point of Sale refund review screen that allows users to proceed with processing the refund after reviewing the refund details, items, and total amount."
        )

        static let editRefundButton = NSLocalizedString(
            "pos.refundReviewView.editRefundButton",
            value: "Edit refund",
            comment: "This text appears as a button label on the refund review screen in a point-of-sale app, allowing users to go back and modify the items selected for refund before finalizing the transaction."
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
        onContinue: {},
        onEditRefund: {}
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
        onContinue: {},
        onEditRefund: {}
    )
    .environment(\.posModalParentSize, CGSize(width: 1192, height: 822))
}
#endif
