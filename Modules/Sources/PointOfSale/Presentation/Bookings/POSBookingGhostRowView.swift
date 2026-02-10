import SwiftUI

struct POSBookingGhostRowView: View {
    @ScaledMetric private var scale: CGFloat = 1.0

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: POSSpacing.none) {
                ghostHeaderRow(geometry: geometry)
                    .padding(.bottom, POSSpacing.xSmall)
                ghostDetailsRow(geometry: geometry)
                    .padding(.bottom, POSSpacing.small)
                ghostBadgesRow(geometry: geometry)
            }
        }
        .padding(.horizontal, POSPadding.medium * (1 / scale))
        .padding(.vertical, POSPadding.medium * (1 / scale))
        .frame(height: Constants.cardHeight)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.posSurfaceContainerLowest)
        .posItemCardBorderStyles()
        .geometryGroup()
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func ghostHeaderRow(geometry: GeometryProxy) -> some View {
        HStack(alignment: .center) {
            Rectangle()
                .fill(Color.posOnSurfaceVariantLowest)
                .frame(width: geometry.size.width * 0.4, height: Constants.textLineHeight)
                .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value))
                .shimmering()

            Spacer()

            Circle()
                .fill(Color.posOnSurfaceVariantLowest)
                .frame(width: Constants.avatarSize, height: Constants.avatarSize)
                .shimmering()
        }
        .frame(height: Constants.rowHeight)
    }

    @ViewBuilder
    private func ghostDetailsRow(geometry: GeometryProxy) -> some View {
        Rectangle()
            .fill(Color.posOnSurfaceVariantLowest)
            .frame(width: geometry.size.width * 0.55, height: Constants.textLineHeight)
            .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value))
            .shimmering()
            .frame(height: Constants.rowHeight, alignment: .leading)
    }

    @ViewBuilder
    private func ghostBadgesRow(geometry: GeometryProxy) -> some View {
        HStack(spacing: POSSpacing.small) {
            Rectangle()
                .fill(Color.posOnSurfaceVariantLowest)
                .frame(width: geometry.size.width * 0.2, height: Constants.badgeHeight)
                .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value))
                .shimmering()

            Rectangle()
                .fill(Color.posOnSurfaceVariantLowest)
                .frame(width: geometry.size.width * 0.2, height: Constants.badgeHeight)
                .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value))
                .shimmering()
        }
        .frame(height: Constants.badgeRowHeight)
    }
}

private enum Constants {
    static let avatarSize: CGFloat = 24
    static let textLineHeight: CGFloat = 16
    static let rowHeight: CGFloat = 24
    static let badgeHeight: CGFloat = 20
    static let badgeRowHeight: CGFloat = 28

    /// Matches the production row: 3 rows (24+24+28) + spacing gaps (4+8) + vertical padding (16+16)
    static let cardHeight: CGFloat = rowHeight + rowHeight + badgeRowHeight + POSSpacing.xSmall + POSSpacing.small + POSPadding.medium * 2
}
