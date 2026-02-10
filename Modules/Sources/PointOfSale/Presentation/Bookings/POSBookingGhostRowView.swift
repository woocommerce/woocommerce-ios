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
        .frame(height: cardHeight)
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
                .frame(width: geometry.size.width * 0.4, height: Constants.textLineHeight * scale)
                .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value))
                .shimmering()

            Spacer()

            Circle()
                .fill(Color.posOnSurfaceVariantLowest)
                .frame(width: Constants.avatarSize * scale, height: Constants.avatarSize * scale)
                .shimmering()
        }
        .frame(maxHeight: .infinity)
    }

    @ViewBuilder
    private func ghostDetailsRow(geometry: GeometryProxy) -> some View {
        Rectangle()
            .fill(Color.posOnSurfaceVariantLowest)
            .frame(width: geometry.size.width * 0.55, height: Constants.textLineHeight * scale)
            .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value))
            .shimmering()
            .frame(maxHeight: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func ghostBadgesRow(geometry: GeometryProxy) -> some View {
        HStack(spacing: POSSpacing.small) {
            Rectangle()
                .fill(Color.posOnSurfaceVariantLowest)
                .frame(width: geometry.size.width * 0.2, height: Constants.badgeHeight * scale)
                .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value))
                .shimmering()

            Rectangle()
                .fill(Color.posOnSurfaceVariantLowest)
                .frame(width: geometry.size.width * 0.2, height: Constants.badgeHeight * scale)
                .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value))
                .shimmering()
        }
        .frame(maxHeight: .infinity)
    }

    /// Matches production row height: content rows scale with dynamic type,
    /// spacing and padding stay fixed (same as POSBookingRowView).
    private var cardHeight: CGFloat {
        let rowHeight = Constants.rowHeight * scale
        let badgeRowHeight = Constants.badgeRowHeight * scale
        let fixedSpacing = POSSpacing.xSmall + POSSpacing.small
        let fixedPadding = POSPadding.medium * (1 / scale) * 2
        return rowHeight + rowHeight + badgeRowHeight + fixedSpacing + fixedPadding
    }
}

private enum Constants {
    static let avatarSize: CGFloat = 24
    static let textLineHeight: CGFloat = 16
    static let rowHeight: CGFloat = 24
    static let badgeHeight: CGFloat = 20
    static let badgeRowHeight: CGFloat = 28
}
