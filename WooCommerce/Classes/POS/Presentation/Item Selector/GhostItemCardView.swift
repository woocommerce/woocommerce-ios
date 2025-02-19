import SwiftUI

struct GhostItemCardView: View {
    @ScaledMetric private var scale: CGFloat = 1.0

    private var dimension: CGFloat {
        min(Constants.productCardSize * scale, Constants.maximumProductCardSize)
    }

    var body: some View {
        HStack(spacing: Constants.cardSpacing) {
            Spacer()
                .frame(width: dimension, height: dimension)
            Rectangle()
                .foregroundColor(.posOnSurfaceVariantLowest)
                .frame(height: Layout.placeholderHeight * scale)
                .cornerRadius(Layout.cornerRadius)
                .padding(.horizontal, Constants.horizontalTextPadding)
            Spacer()
                .frame(width: dimension, height: dimension)
        }
        .shimmering()
        .frame(maxWidth: .infinity, idealHeight: dimension)
        .background(Color.posSurfaceBright)
        .posItemCardBorderStyles()
    }
}

private extension GhostItemCardView {
    typealias Constants = PointOfSaleItemListCardConstants

    enum Layout {
        static let placeholderHeight: CGFloat = 36
        static let cornerRadius: CGFloat = POSCornerRadiusStyle.medium.value
    }
}

#Preview {
    GhostItemCardView()
}
