import SwiftUI

struct GhostItemCardView: View {
    @ScaledMetric private var scale: CGFloat = 1.0
    @State private var viewWidth: CGFloat = 0.0

    private var dimension: CGFloat {
        min(Constants.productCardSize * scale, Constants.maximumProductCardSize)
    }

    var body: some View {
        HStack(alignment: .center, spacing: Constants.cardSpacing) {
            Rectangle()
                .frame(width: dimension, height: dimension)
            VStack(alignment: .leading) {
                Rectangle()
                    .frame(width: viewWidth * 0.5, height: Layout.placeholderHeight * scale)
                    .cornerRadius(Layout.cornerRadius)
                Rectangle()
                    .frame(width: viewWidth * 0.1, height: Layout.placeholderHeight * scale)
                    .cornerRadius(Layout.cornerRadius)
            }
            .padding(.horizontal, Constants.horizontalTextPadding)
            Spacer()
        }
        .measureWidth { width in
            viewWidth = width
        }
        .foregroundColor(.posOnSurfaceVariantLowest)
        .shimmering()
        .frame(maxWidth: .infinity, idealHeight: dimension)
        .background(Color.posSurfaceBright)
        .posItemCardBorderStyles()
    }
}

private extension GhostItemCardView {
    typealias Constants = PointOfSaleItemListCardConstants

    enum Layout {
        static let placeholderHeight: CGFloat = 32
        static let cornerRadius: CGFloat = POSCornerRadiusStyle.medium.value
    }
}

#Preview {
    GhostItemCardView()
}
