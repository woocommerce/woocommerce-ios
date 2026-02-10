import SwiftUI

struct POSBookingDetailsLoadingView: View {
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
                    shimmeringDetailsSection
                }
                .padding(.top, POSPadding.xSmall)
                .padding(.horizontal, POSPadding.medium)
                .padding(.bottom, POSPadding.medium)
            }
        }
        .background(Color.posSurface)
        .navigationBarHidden(true)
    }

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
    private var shimmeringDetailsSection: some View {
        VStack(alignment: .leading, spacing: POSSpacing.medium) {
            shimmeringRow
            shimmeringRow
            shimmeringRow
            shimmeringRow
        }
        .padding(POSPadding.medium)
        .background(Color.posSurfaceContainerLowest)
        .posItemCardBorderStyles()
    }

    @ViewBuilder
    private var shimmeringRow: some View {
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
}

private enum Constants {
    static let longRowWidth: CGFloat = 120
    static let mediumRowWidth: CGFloat = 100
    static let shortRowWidth: CGFloat = 80
}
