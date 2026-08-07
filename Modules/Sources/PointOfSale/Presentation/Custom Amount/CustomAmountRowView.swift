import SwiftUI
import class WooFoundation.CurrencyFormatter
import struct Yosemite.POSCustomAmount

struct CustomAmountRowView: View {
    private let customAmount: POSCustomAmount
    private let showsDiscountNotAppliedNote: Bool
    private let onEdit: (() -> Void)?
    private let onRemove: (() -> Void)?

    @ScaledMetric private var scale: CGFloat = 1.0
    @Environment(\.posCurrencyProvider) private var currencyProvider

    init(customAmount: POSCustomAmount,
         showsDiscountNotAppliedNote: Bool = false,
         onEdit: (() -> Void)? = nil,
         onRemove: (() -> Void)? = nil) {
        self.customAmount = customAmount
        self.showsDiscountNotAppliedNote = showsDiscountNotAppliedNote
        self.onEdit = onEdit
        self.onRemove = onRemove
    }

    private var dimension: CGFloat {
        min(Constants.iconSize * scale, Constants.maximumIconSize)
    }

    var body: some View {
        HStack(spacing: Constants.horizontalElementSpacing) {
            CustomAmountAvatar(name: customAmount.name)
                .frame(width: dimension, height: dimension)

            VStack(alignment: .leading, spacing: POSSpacing.xSmall * (1 / scale)) {
                Text(customAmount.name)
                    .foregroundColor(PointOfSaleItemListCardConstants.titleColor)
                    .font(Constants.titleFont)
                    .lineLimit(2)

                Text(formattedAmount)
                    .foregroundColor(PointOfSaleItemListCardConstants.detailColor)
                    .font(Constants.amountFont)

                if showsDiscountNotAppliedNote {
                    Text(Localization.discountNotApplied)
                        .foregroundColor(.posAlert)
                        .font(Constants.amountFont)
                }
            }
            .animation(.default, value: showsDiscountNotAppliedNote)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)

            if let onEdit {
                CartRowEditButton(action: onEdit)
            }

            if let onRemove {
                CartRowRemoveButton(action: onRemove)
            }
        }
        .padding(.trailing, Constants.cardContentHorizontalPadding)
        .frame(maxWidth: .infinity, idealHeight: Constants.iconSize * scale)
        .background(Color.posSurfaceContainerLowest)
        .posItemCardBorderStyles()
        .padding(.horizontal, Constants.horizontalPadding)
        .accessibilityIdentifier("pos-custom-amount-row")
    }

    private var formattedAmount: String {
        let formatter = CurrencyFormatter(currencySettings: currencyProvider.currencySettings)
        return formatter.formatAmount(customAmount.amount) ?? customAmount.amount
    }
}

private extension CustomAmountRowView {
    enum Localization {
        static let discountNotApplied = NSLocalizedString(
            "pointOfSale.customAmountRow.discountNotApplied",
            value: "Discount not applied",
            comment: "Note shown on a custom amount row in the Point of Sale cart at checkout "
                + "when a coupon is applied, since coupons never discount custom amounts.")
    }

    enum Constants {
        static let iconSize: CGFloat = 96
        static let maximumIconSize: CGFloat = Self.iconSize * 1.5
        static let horizontalPadding: CGFloat = POSPadding.medium
        static let horizontalElementSpacing: CGFloat = POSSpacing.medium
        static let cardContentHorizontalPadding: CGFloat = POSPadding.medium
        static let titleFont: POSFontStyle = .posBodySmallBold()
        static let amountFont: POSFontStyle = .posBodySmallRegular()
    }
}

#if DEBUG
#Preview(traits: .sizeThatFitsLayout) {
    CustomAmountRowView(
        customAmount: POSCustomAmount(name: "Service fee", amount: "12.50", isTaxable: true),
        onEdit: {},
        onRemove: {}
    )
}

#Preview("Read-only", traits: .sizeThatFitsLayout) {
    CustomAmountRowView(
        customAmount: POSCustomAmount(name: "Service fee", amount: "12.50", isTaxable: true)
    )
}

#Preview("Discount not applied", traits: .sizeThatFitsLayout) {
    CustomAmountRowView(
        customAmount: POSCustomAmount(name: "Service fee", amount: "12.50", isTaxable: true),
        showsDiscountNotAppliedNote: true
    )
}
#endif
