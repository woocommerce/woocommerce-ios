import SwiftUI
import StoreDesignSystem
import struct Yosemite.BlazeBillingSummary

/// Notice about the outstanding Blaze balance, listing the unpaid orders with links to pay them.
struct BlazeOutstandingBalanceView: View {
    private let summary: BlazeBillingSummary
    private let onPay: (BlazeBillingSummary.PaymentLink) -> Void

    init(summary: BlazeBillingSummary,
         onPay: @escaping (BlazeBillingSummary.PaymentLink) -> Void) {
        self.summary = summary
        self.onPay = onPay
    }

    var body: some View {
        VStack(alignment: .leading, spacing: StoreSpacing.s4) {
            StoreNoticeBanner(Localization.title,
                              description: String(format: Localization.message, Self.formattedAmount(summary.debt)),
                              tone: .error,
                              icon: StoreIcon.CircleInfo.regular)

            VStack(spacing: StoreSpacing.s4) {
                ForEach(Array(summary.paymentLinks.enumerated()), id: \.offset) { _, paymentLink in
                    paymentLinkRow(paymentLink)
                }
            }
            .padding(StorePadding.p6)
            .overlay {
                RoundedRectangle(cornerRadius: StoreRadius.large)
                    .strokeBorder(Color.storeOutlineVariant, lineWidth: StoreStrokeWidth.regular)
            }
        }
    }
}

private extension BlazeOutstandingBalanceView {
    func paymentLinkRow(_ paymentLink: BlazeBillingSummary.PaymentLink) -> some View {
        HStack(spacing: StoreSpacing.s4) {
            VStack(alignment: .leading, spacing: StoreSpacing.s1) {
                if let date = paymentLink.date {
                    Text(date.formatted(date: .long, time: .omitted))
                        .storeTextStyle(.bodyMedium)
                        .foregroundStyle(Color.storeOnSurfaceVariant)
                }
                Text(Self.formattedAmount(paymentLink.amount))
                    .storeTextStyle(.bodyLarge.emphasized)
                    .foregroundStyle(Color.storeOnSurface)
            }
            Spacer()
            StoreButton(Localization.pay, variant: .outlined) {
                onPay(paymentLink)
            }
        }
    }

    static func formattedAmount(_ amount: Double) -> String {
        amount.formatted(.currency(code: Constants.currencyCode))
    }
}

private extension BlazeOutstandingBalanceView {
    enum Constants {
        static let currencyCode = "USD"
    }

    enum Localization {
        static let title = NSLocalizedString(
            "blazeOutstandingBalanceView.title",
            value: "Outstanding balance",
            comment: "Title of the notice shown on the Blaze campaign list when the account has unpaid Blaze orders."
        )
        static let message = NSLocalizedString(
            "blazeOutstandingBalanceView.message",
            value: "Your account currently has an outstanding balance of %1$@. Please pay it before creating new campaigns.",
            comment: "Message of the notice shown on the Blaze campaign list when the account has unpaid Blaze orders. " +
            "%1$@ is the formatted outstanding amount, e.g. $25.05."
        )
        static let pay = NSLocalizedString(
            "blazeOutstandingBalanceView.pay",
            value: "Pay",
            comment: "Button to open the payment page of an unpaid Blaze order."
        )
    }
}

#Preview("Single unpaid order") {
    BlazeOutstandingBalanceView(summary: .init(debt: 25.05,
                                               paymentLinks: [.init(date: Date(), amount: 25.05, url: "https://example.com")]),
                                onPay: { _ in })
    .padding()
}

#Preview("Multiple unpaid orders") {
    BlazeOutstandingBalanceView(summary: .init(debt: 60.05,
                                               paymentLinks: [.init(date: Date(), amount: 25.05, url: "https://example.com"),
                                                              .init(date: nil, amount: 35, url: "https://example.com")]),
                                onPay: { _ in })
    .padding()
}
