import SwiftUI

struct POSOrderDetailsLoadingView: View {
    var body: some View {
        VStack(spacing: POSSpacing.none) {
            POSPageHeaderView(
                title: "",
                backButtonConfiguration: nil,
                leadingContent: { shimmeringHeaderLeadingContent },
                trailingContent: { shimmeringHeaderTrailingContent },
                bottomContent: { shimmeringHeaderBottomContent }
            )
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)

            ScrollView {
                VStack(alignment: .leading, spacing: POSSpacing.medium) {
                    shimmeringProductsSection
                    shimmeringTotalsSection
                }
                .padding(.top, POSPadding.xSmall)
                .padding(.horizontal, POSPadding.medium)
                .padding(.bottom, POSPadding.medium)
            }
        }
        .background(Color.posSurface)
        .navigationBarHidden(true)
    }

    // MARK: - Shimmer Components

    @ViewBuilder
    private var shimmeringHeaderLeadingContent: some View {
        HStack {
            Rectangle()
                .fill(Color.posOnSurfaceVariantLowest)
                .frame(width: Constants.longRowWidth, height: POSPadding.xxLarge)
                .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value))
                .shimmering()
            Spacer()
        }
    }

    @ViewBuilder
    private var shimmeringHeaderTrailingContent: some View {
        HStack {
            Spacer()
            Rectangle()
                .fill(Color.posOnSurfaceVariantLowest)
                .frame(width: Constants.shortRowWidth, height: POSPadding.large)
                .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value))
                .shimmering()
        }
    }

    @ViewBuilder
    private var shimmeringHeaderBottomContent: some View {
        VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
            Rectangle()
                .fill(Color.posOnSurfaceVariantLowest)
                .frame(width: Constants.longRowWidth, height: POSPadding.medium)
                .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value))
                .shimmering()

            Spacer().frame(height: POSSpacing.xSmall)

            Rectangle()
                .fill(Color.posOnSurfaceVariantLowest)
                .frame(width: Constants.shortRowWidth, height: POSPadding.medium)
                .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value))
                .shimmering()
        }
        .padding(.top, POSPadding.medium)
        .multilineTextAlignment(.leading)
    }

    @ViewBuilder
    private var shimmeringProductsSection: some View {
        VStack(alignment: .leading, spacing: POSSpacing.medium) {
            Text(Localization.productsTitle)
                .font(.posBodyXLargeBold)
                .foregroundStyle(Color.posOnSurface)

            VStack(spacing: POSSpacing.small) {
                ForEach(0..<2, id: \.self) { index in
                    shimmeringProductRow

                    if index < 1 {
                        divider
                    }
                }
            }
        }
        .padding(POSPadding.medium)
        .background(Color.posSurfaceContainerLowest)
        .posItemCardBorderStyles()
    }

    @ViewBuilder
    private var shimmeringProductRow: some View {
        HStack(alignment: .center, spacing: POSSpacing.medium) {
            Rectangle()
                .fill(Color.posOnSurfaceVariantLowest)
                .frame(width: POSPadding.xxLarge, height: POSPadding.xxLarge)
                .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value))
                .shimmering()

            VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
                Rectangle()
                    .fill(Color.posOnSurfaceVariantLowest)
                    .frame(width: Constants.longRowWidth, height: POSPadding.medium)
                    .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value))
                    .shimmering()

                Rectangle()
                    .fill(Color.posOnSurfaceVariantLowest)
                    .frame(width: Constants.shortRowWidth, height: POSPadding.medium)
                    .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value))
                    .shimmering()
            }

            Spacer()

            Rectangle()
                .fill(Color.posOnSurfaceVariantLowest)
                .frame(width: Constants.shortRowWidth, height: POSPadding.medium)
                .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value))
                .shimmering()
        }
    }

    @ViewBuilder
    private var shimmeringTotalsSection: some View {
        VStack(alignment: .leading, spacing: POSSpacing.medium) {
            Text(Localization.totalsTitle)
                .font(.posBodyXLargeBold)
                .foregroundStyle(Color.posOnSurface)

            VStack(spacing: POSSpacing.medium) {
                shimmeringTotalsRow
                shimmeringTotalsRow
                shimmeringTotalsRow

                divider
                shimmeringTotalsRow

                divider
                shimmeringTotalsRow
            }
        }
        .padding(POSPadding.medium)
        .background(Color.posSurfaceContainerLowest)
        .posItemCardBorderStyles()
    }

    @ViewBuilder
    private var shimmeringTotalsRow: some View {
        HStack {
            Rectangle()
                .fill(Color.posOnSurfaceVariantLowest)
                .frame(width: Constants.mediumRowWidth, height: POSPadding.large)
                .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value))
                .shimmering()

            Spacer()

            Rectangle()
                .fill(Color.posOnSurfaceVariantLowest)
                .frame(width: Constants.shortRowWidth, height: POSPadding.large)
                .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value))
                .shimmering()
        }
    }

    @ViewBuilder
    private var divider: some View {
        Divider()
            .overlay(Color.posOutlineVariant.opacity(0.5))
            .padding(.vertical, POSSpacing.small)
    }
}

private enum Constants {
    static let longRowWidth: CGFloat = 120
    static let mediumRowWidth: CGFloat = 100
    static let shortRowWidth: CGFloat = 80
}

private enum Localization {
    static let productsTitle = NSLocalizedString(
        "pos.orderDetailsLoadingView.productsTitle",
        value: "Products",
        comment: "Section title for the products list"
    )

    static let totalsTitle = NSLocalizedString(
        "pos.orderDetailsLoadingView.totalsTitle",
        value: "Totals",
        comment: "Section title for the order totals breakdown"
    )
}

#if DEBUG
#Preview {
    POSOrderDetailsLoadingView()
}
#endif
