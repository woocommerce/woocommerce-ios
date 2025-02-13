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
                .frame(height: 36 * scale)
                .cornerRadius(8)
                .padding(.horizontal, Constants.horizontalTextPadding)
            Spacer()
                .frame(width: dimension, height: dimension)
        }
        .shimmering()
    }
}

private extension GhostItemCardView {
    typealias Constants = PointOfSaleItemListCardConstants
}

#Preview {
    GhostItemCardView()
}
