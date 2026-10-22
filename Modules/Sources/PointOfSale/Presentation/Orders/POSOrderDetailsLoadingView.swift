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
            .accessibilityHidden(true)

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

    private var shimmeringHeaderLeadingContent: some View {
        HStack {
            POSPlaceholderText(.redactedPlaceholder(length: 5), font: .posHeadingBold)
            Spacer()
        }
    }

    private var shimmeringHeaderTrailingContent: some View {
        HStack {
            Spacer()
            POSPlaceholderText(.redactedPlaceholder(length: 6), font: .posBodyMediumBold)
                // Match the Email receipt button's extra-small content padding.
                .padding(.vertical, POSPadding.small)
                .padding(.horizontal, POSPadding.medium)
        }
    }

    private var shimmeringHeaderBottomContent: some View {
        VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
            POSPlaceholderText(.redactedPlaceholder(length: 9), font: .posBodyMediumRegular())
            POSPlaceholderText(.redactedPlaceholder(length: 9), font: .posBodyMediumRegular())

            Spacer().frame(height: POSSpacing.xSmall)
            POSPlaceholderText(.redactedPlaceholder(length: 6), font: .posCaptionRegular)
                .padding(.vertical, POSPadding.xSmall)
        }
        .padding(.top, POSSpacing.xSmall)
        .multilineTextAlignment(.leading)
    }

    @ViewBuilder
    private var shimmeringProductsSection: some View {
        VStack(alignment: .leading, spacing: POSSpacing.medium) {
            Text(Localization.itemsTitle)
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
                .fill(Color.posOnSurfaceVariantLowest.opacity(POSLoadingPlaceholderStyle.imageBaseOpacity))
                .frame(width: Constants.productImageSize, height: Constants.productImageSize)
                .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value))
                .shimmering(gradient: POSLoadingPlaceholderStyle.shimmerGradient)

            VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
                POSPlaceholderText(.redactedPlaceholder(length: 8), font: .posBodyLargeBold)

                POSPlaceholderText(.redactedPlaceholder(length: 6), font: .posBodyMediumRegular())
            }

            Spacer()

            POSPlaceholderText(.redactedPlaceholder(length: 6), font: .posBodyMediumRegular())
        }
    }

    @ViewBuilder
    private var shimmeringTotalsSection: some View {
        VStack(alignment: .leading, spacing: POSSpacing.medium) {
            Text(Localization.totalsTitle)
                .font(.posBodyXLargeBold)
                .foregroundStyle(Color.posOnSurface)

            VStack(spacing: POSSpacing.medium) {
                shimmeringTotalsRow()
                shimmeringTotalsRow()
                shimmeringTotalsRow()

                divider
                shimmeringTotalsRow(titleFont: .posBodyLargeBold)

                divider
                shimmeringTotalsRow(titleFont: .posBodyLargeBold)
            }
        }
        .padding(POSPadding.medium)
        .background(Color.posSurfaceContainerLowest)
        .posItemCardBorderStyles()
    }

    @ViewBuilder
    private func shimmeringTotalsRow(titleFont: POSFontStyle = .posBodyMediumRegular()) -> some View {
        HStack {
            POSPlaceholderText(.redactedPlaceholder(length: 7), font: titleFont)

            Spacer()

            POSPlaceholderText(.redactedPlaceholder(length: 6), font: .posBodyMediumRegular())
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
    // Matches the loaded order details product image.
    static let productImageSize: CGFloat = 56
}

private enum Localization {
    static let itemsTitle = NSLocalizedString(
        "pos.orderDetailsLoadingView.itemsTitle",
        value: "Items",
        comment: "Section title for the items list (products and custom amounts) shown in the loading skeleton"
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
