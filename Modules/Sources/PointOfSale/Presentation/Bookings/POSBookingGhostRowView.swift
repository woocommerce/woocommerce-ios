import SwiftUI

struct POSBookingGhostRowView: View {
    @ScaledMetric private var scale: CGFloat = 1.0
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    private var minHeight: CGFloat {
        min(Constants.bookingCardMinHeight * scale, Constants.maximumBookingCardHeight)
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
                Spacer().frame(minHeight: 0)
                ghostHeaderRow(geometry: geometry)
                ghostDetailsColumn(geometry: geometry)
                Spacer().frame(height: POSSpacing.xSmall)
                ghostStatusRow(geometry: geometry)
                Spacer().frame(minHeight: 0)
            }
        }
        .padding(.horizontal, POSPadding.medium * (1 / scale))
        .padding(.vertical, POSPadding.medium * (1 / scale))
        .frame(height: minHeight, alignment: .leading)
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
                .frame(width: geometry.size.width * 0.3, height: POSPadding.medium)
                .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value))
                .shimmering()

            Spacer()

            Rectangle()
                .fill(Color.posOnSurfaceVariantLowest)
                .frame(width: geometry.size.width * 0.2, height: POSPadding.medium)
                .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value))
                .shimmering()
        }
    }

    @ViewBuilder
    private func ghostDetailsColumn(geometry: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
            Rectangle()
                .fill(Color.posOnSurfaceVariantLowest)
                .frame(width: geometry.size.width * 0.45, height: POSPadding.medium)
                .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value))
                .shimmering()

            Rectangle()
                .fill(Color.posOnSurfaceVariantLowest)
                .frame(width: geometry.size.width * 0.35, height: POSPadding.medium)
                .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value))
                .shimmering()
        }
    }

    @ViewBuilder
    private func ghostStatusRow(geometry: GeometryProxy) -> some View {
        Rectangle()
            .fill(Color.posOnSurfaceVariantLowest)
            .frame(width: geometry.size.width * 0.22, height: POSPadding.medium)
            .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value))
            .shimmering()
    }
}

private enum Constants {
    static let bookingCardMinHeight: CGFloat = 112
    static let maximumBookingCardHeight: CGFloat = bookingCardMinHeight * 2
}
