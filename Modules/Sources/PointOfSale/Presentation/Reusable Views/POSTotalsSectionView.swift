import SwiftUI
import struct Yosemite.POSOrderRefund

/// A reusable totals breakdown card used by both order details and booking details.
///
/// Displays subtotal, optional discount, tax, total, paid amount with payment method,
/// and optional refund rows with net payment.
struct POSTotalsSectionView: View {
    let sectionTitle: String
    let subtotalLabel: String
    let subtotalAmount: String
    let discountAmount: String?
    let taxAmount: String
    let totalAmount: String
    let paidAmount: String?
    let paymentMethodTitle: String
    let refunds: [POSOrderRefund]
    let netAmount: String?

    var body: some View {
        VStack(alignment: .leading, spacing: POSSpacing.medium) {
            Text(sectionTitle)
                .font(.posBodyXLargeRegular)
                .foregroundStyle(Color.posOnSurface)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: POSSpacing.small) {
                totalsRow(title: subtotalLabel, amount: subtotalAmount)

                totalsRow(title: Localization.taxesLabel, amount: taxAmount)

                if let discountAmount {
                    totalsRow(title: Localization.discountLabel, amount: discountAmount)
                }
            }

            sectionDivider

            totalsRow(
                title: Localization.totalLabel,
                amount: totalAmount,
                titleColor: .posOnSurface,
                titleFont: .posBodyLargeBold
            )

            if let paidAmount {
                sectionDivider
                paidAmountRow

                if !refunds.isEmpty {
                    sectionDivider
                    refundsContent
                }
            }
        }
        .padding(POSPadding.medium)
        .background(Color.posSurfaceContainerLowest)
        .posItemCardBorderStyles()
    }

    // MARK: - Paid Row

    private var paidAmountRow: some View {
        VStack(alignment: .leading, spacing: POSSpacing.none) {
            if let paidAmount {
                totalsRow(
                    title: Localization.paidLabel,
                    amount: paidAmount,
                    titleColor: .posOnSurface,
                    titleFont: .posBodyLargeBold
                )
            }

            if !paymentMethodTitle.isEmpty {
                Text(paymentMethodTitle)
                    .font(.posBodyMediumRegular())
                    .foregroundStyle(Color.posOnSurfaceVariantHighest)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Localization.paidAccessibilityLabel(amount: paidAmount ?? "", method: paymentMethodTitle))
    }

    // MARK: - Refunds

    @ViewBuilder
    private var refundsContent: some View {
        ForEach(refunds.sorted(by: { $0.refundID < $1.refundID }), id: \.refundID) { refund in
            refundRow(refund: refund)
            sectionDivider
        }

        if let netAmount {
            totalsRow(
                title: Localization.netPaymentLabel,
                amount: netAmount,
                titleColor: .posOnSurface,
                titleFont: .posBodyLargeBold,
                accessibilityLabel: Localization.netPaymentAccessibilityLabel(netAmount)
            )
        }
    }

    @ViewBuilder
    private func refundRow(refund: POSOrderRefund) -> some View {
        VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
            totalsRow(
                title: Localization.refundLabel,
                amount: refund.formattedTotal,
                titleColor: .posOnSurface,
                titleFont: .posBodyLargeBold
            )

            if let reason = refund.reason, !reason.isEmpty {
                Text(Localization.reasonLabel(reason))
                    .font(.posBodyMediumRegular())
                    .foregroundStyle(Color.posOnSurfaceVariantHighest)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Localization.refundAccessibilityLabel(amount: refund.formattedTotal, reason: refund.reason))
    }

    // MARK: - Generic Row

    @ViewBuilder
    private func totalsRow(
        title: String,
        amount: String,
        titleColor: Color = .posOnSurfaceVariantHighest,
        titleFont: POSFontStyle = .posBodyMediumRegular(),
        accessibilityLabel: String? = nil
    ) -> some View {
        HStack {
            Text(title)
                .font(titleFont)
                .foregroundStyle(titleColor)
            Spacer()
            Text(amount)
                .font(.posBodyMediumRegular())
                .foregroundStyle(Color.posOnSurface)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel ?? Localization.rowAccessibilityLabel(title: title, amount: amount))
    }

    private var sectionDivider: some View {
        Divider()
            .overlay(Color.posOutlineVariant.opacity(0.5))
    }
}

// MARK: - Localization

private enum Localization {
    static let discountLabel = NSLocalizedString(
        "pos.totalsSectionView.discountLabel.v2",
        value: "Discount",
        comment: "Label for discount in the totals breakdown."
    )

    static let taxesLabel = NSLocalizedString(
        "pos.totalsSectionView.taxesLabel",
        value: "Taxes",
        comment: "Label for taxes in the totals breakdown."
    )

    static let totalLabel = NSLocalizedString(
        "pos.totalsSectionView.totalLabel",
        value: "Total",
        comment: "Label for the total amount in the totals breakdown."
    )

    static let paidLabel = NSLocalizedString(
        "pos.totalsSectionView.paidLabel",
        value: "Total paid",
        comment: "Label for the paid amount in the totals breakdown."
    )

    static let refundLabel = NSLocalizedString(
        "pos.totalsSectionView.refundLabel",
        value: "Refunded",
        comment: "Label for a refund entry in the totals breakdown."
    )

    static func reasonLabel(_ reason: String) -> String {
        let format = NSLocalizedString(
            "pos.totalsSectionView.reasonLabel",
            value: "Reason: %1$@",
            comment: "Label for refund reason. %1$@ is the reason text."
        )
        return String(format: format, reason)
    }

    static let netPaymentLabel = NSLocalizedString(
        "pos.totalsSectionView.netPaymentLabel",
        value: "Net Payment",
        comment: "Label for net payment amount after refunds."
    )

    // MARK: - Accessibility

    static func paidAccessibilityLabel(amount: String, method: String) -> String {
        let baseFormat = NSLocalizedString(
            "pos.totalsSectionView.paid.accessibilityLabel",
            value: "Total paid: %1$@",
            comment: "Accessibility label for total paid. %1$@ is the paid amount."
        )
        var label = String(format: baseFormat, amount)

        if !method.isEmpty {
            let methodFormat = NSLocalizedString(
                "pos.totalsSectionView.paid.accessibilityLabel.method",
                value: "Payment method: %1$@",
                comment: "Payment method portion of paid accessibility label. %1$@ is the payment method."
            )
            label += ", " + String(format: methodFormat, method)
        }

        return label
    }

    static func refundAccessibilityLabel(amount: String, reason: String?) -> String {
        let baseFormat = NSLocalizedString(
            "pos.totalsSectionView.refund.accessibilityLabel",
            value: "Refunded: %1$@",
            comment: "Accessibility label for refunded amount. %1$@ is the refund amount."
        )
        var label = String(format: baseFormat, amount)

        if let reason = reason, !reason.isEmpty {
            let reasonFormat = NSLocalizedString(
                "pos.totalsSectionView.refund.accessibilityLabel.reason",
                value: "Reason: %1$@",
                comment: "Reason portion of refund accessibility label. %1$@ is the refund reason."
            )
            label += ", " + String(format: reasonFormat, reason)
        }

        return label
    }

    static func rowAccessibilityLabel(title: String, amount: String) -> String {
        let format = NSLocalizedString(
            "pos.totalsSectionView.row.accessibilityLabel",
            value: "%1$@: %2$@",
            comment: "Accessibility label for a totals row. %1$@ is the row title, %2$@ is the amount."
        )
        return String(format: format, title, amount)
    }

    static func netPaymentAccessibilityLabel(_ amount: String) -> String {
        let format = NSLocalizedString(
            "pos.totalsSectionView.netPayment.accessibilityLabel",
            value: "Net payment: %1$@",
            comment: "Accessibility label for net payment. %1$@ is the net payment amount after refunds."
        )
        return String(format: format, amount)
    }
}
