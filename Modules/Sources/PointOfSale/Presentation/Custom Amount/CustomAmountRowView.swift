import SwiftUI
import class WooFoundation.CurrencyFormatter
import struct Yosemite.POSCustomAmount

struct CustomAmountRowView: View {
    private let customAmount: POSCustomAmount
    private let onEdit: (() -> Void)?
    private let onRemove: (() -> Void)?

    @ScaledMetric private var scale: CGFloat = 1.0
    @Environment(\.posCurrencyProvider) private var currencyProvider

    init(customAmount: POSCustomAmount,
         onEdit: (() -> Void)? = nil,
         onRemove: (() -> Void)? = nil) {
        self.customAmount = customAmount
        self.onEdit = onEdit
        self.onRemove = onRemove
    }

    private var dimension: CGFloat {
        min(Constants.iconSize * scale, Constants.maximumIconSize)
    }

    var body: some View {
        HStack(spacing: Constants.horizontalElementSpacing) {
            ZStack {
                Color.posSurfaceContainerLow

                Image(systemName: "tag")
                    .font(.posButtonSymbolMedium)
                    .foregroundColor(.posOnSurface)
            }
            .frame(width: dimension, height: dimension)
            .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.medium.value))

            VStack(alignment: .leading, spacing: POSSpacing.xSmall * (1 / scale)) {
                Text(customAmount.name)
                    .foregroundColor(PointOfSaleItemListCardConstants.titleColor)
                    .font(Constants.titleFont)
                    .lineLimit(2)

                Text(formattedAmount)
                    .foregroundColor(PointOfSaleItemListCardConstants.detailColor)
                    .font(Constants.amountFont)
            }
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
#endif
