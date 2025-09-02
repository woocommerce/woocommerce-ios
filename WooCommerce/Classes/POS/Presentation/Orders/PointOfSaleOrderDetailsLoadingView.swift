import SwiftUI

struct PointOfSaleOrderDetailsLoadingView: View {
    var body: some View {
        VStack(spacing: 0) {
            POSPageHeaderView(
                title: Localization.orderDetailsTitle,
                backButtonConfiguration: nil,
                trailingContent: { shimmeringHeaderTrailingContent },
                bottomContent: { shimmeringHeaderBottomContent }
            )

            ScrollView {
                VStack(alignment: .leading, spacing: POSSpacing.medium) {
                    shimmeringProductsSection
                    shimmeringTotalsSection
                }
                .padding(.horizontal, POSPadding.medium)
            }
        }
        .background(Color.posSurface)
        .navigationBarHidden(true)
    }

    // MARK: - Shimmer Components

    @ViewBuilder
    private var shimmeringHeaderTrailingContent: some View {
        GeometryReader { geometry in
            HStack {
                Spacer()
                Rectangle()
                    .fill(Color.posOnSurfaceVariantLowest)
                    .frame(width: geometry.size.width * 0.3, height: 16)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .shimmering()
            }
        }
        .frame(height: 16)
    }

    @ViewBuilder
    private var shimmeringHeaderBottomContent: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
                Rectangle()
                    .fill(Color.posOnSurfaceVariantLowest)
                    .frame(width: geometry.size.width * 0.5, height: 16)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .shimmering()
            }
        }
        .frame(height: 16)
    }

    @ViewBuilder
    private var shimmeringProductsSection: some View {
        VStack(alignment: .leading, spacing: POSSpacing.medium) {
            Text(Localization.productsTitle)
                .font(.posBodyLargeBold)
                .foregroundStyle(Color.posOnSurface)

            VStack(spacing: POSSpacing.small) {
                ForEach(0..<2, id: \.self) { _ in
                    shimmeringProductRow
                }
            }
        }
        .padding(POSPadding.medium)
        .background(Color.posSurfaceContainerLowest)
        .posItemCardBorderStyles()
    }

    @ViewBuilder
    private var shimmeringProductRow: some View {
        GeometryReader { geometry in
            HStack(alignment: .top, spacing: POSSpacing.medium) {
                Rectangle()
                    .fill(Color.posOnSurfaceVariantLowest)
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value))
                    .shimmering()

                VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
                    Rectangle()
                        .fill(Color.posOnSurfaceVariantLowest)
                        .frame(width: geometry.size.width * 0.45, height: 20)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .shimmering()

                    Rectangle()
                        .fill(Color.posOnSurfaceVariantLowest)
                        .frame(width: geometry.size.width * 0.35, height: 16)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .shimmering()
                }

                Spacer()

                Rectangle()
                    .fill(Color.posOnSurfaceVariantLowest)
                    .frame(width: geometry.size.width * 0.2, height: 20)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .shimmering()
            }
            .padding(.vertical, POSPadding.small)
        }
        .frame(height: 60)
    }

    @ViewBuilder
    private var shimmeringTotalsSection: some View {
        VStack(alignment: .leading, spacing: POSSpacing.medium) {
            Text(Localization.totalsTitle)
                .font(.posBodyLargeBold)
                .foregroundStyle(Color.posOnSurface)

            VStack(spacing: POSSpacing.medium) {
                shimmeringTotalsRow
                shimmeringTotalsRow
                shimmeringTotalsRow

                Divider()
                    .background(Color.posSurfaceDim)

                shimmeringTotalsRow
                shimmeringTotalsRow
            }
        }
        .padding(POSPadding.medium)
        .background(Color.posSurfaceContainerLowest)
        .posItemCardBorderStyles()
    }

    @ViewBuilder
    private var shimmeringTotalsRow: some View {
        GeometryReader { geometry in
            HStack {
                Rectangle()
                    .fill(Color.posOnSurfaceVariantLowest)
                    .frame(width: geometry.size.width * 0.3, height: 20)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .shimmering()

                Spacer()

                Rectangle()
                    .fill(Color.posOnSurfaceVariantLowest)
                    .frame(width: geometry.size.width * 0.25, height: 20)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .shimmering()
            }
        }
        .frame(height: 20)
    }
}

private enum Localization {
    static let orderDetailsTitle = NSLocalizedString(
        "pos.orderDetailsLoadingView.title",
        value: "Order",
        comment: "Title for the order details screen when no specific order is selected"
    )

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
    PointOfSaleOrderDetailsLoadingView()
}
#endif
