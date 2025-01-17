import SwiftUI

/// Displays a card for a parent product in POS.
struct ParentProductCardView: View {
    private let name: String
    private let imageSource: String?
    private let detailText: String

    @ScaledMetric private var scale: CGFloat = 1.0

    private var dimension: CGFloat {
        min(Constants.productCardSize * scale, Constants.maximumProductCardSize)
    }

    init(name: String, imageSource: String?, detailText: String) {
        self.name = name
        self.imageSource = imageSource
        self.detailText = detailText
    }

    var body: some View {
        HStack(spacing: Constants.cardSpacing) {
            POSItemImageView(imageSource: imageSource,
                             imageSize: dimension,
                             scale: 1)
            .frame(width: dimension, height: dimension)

            VStack(alignment: .leading, spacing: Constants.textSpacing) {
                Text(name)
                    .lineLimit(2)
                    .foregroundStyle(Color.posPrimaryText)
                    .multilineTextAlignment(.leading)
                    .font(Constants.itemNameFont)

                Text(detailText)
                    .foregroundStyle(Color.posSecondaryText)
                    .font(Constants.itemDetailFont)
            }
            .padding(.horizontal, Constants.horizontalTextPadding * (1 / scale))
            .padding(.vertical, Constants.verticalTextPadding * (1 / scale))
            Spacer()
        }
        .frame(maxWidth: .infinity, idealHeight: dimension)
        .background(Color.posSecondaryBackground)
        .posItemCardBorderStyles()
    }
}

private typealias Constants = PointOfSaleItemListCardConstants

#if DEBUG
#Preview {
    ParentProductCardView(name: "Parent product",
                          imageSource: nil,
                          detailText: "Detail text")
}
#endif
