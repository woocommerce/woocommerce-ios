import SwiftUI

/// Displays a card for a parent product in POS.
struct ParentProductCardView: View {
    private let name: String
    private let imageSource: String?
    private let detailText: String

    @ScaledMetric private var scale: CGFloat = 1.0
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    init(name: String, imageSource: String?, detailText: String) {
        self.name = name
        self.imageSource = imageSource
        self.detailText = detailText
    }

    var body: some View {
        HStack(spacing: Constants.cardSpacing) {
            POSItemImageView(imageSource: imageSource,
                             imageSize: Constants.productCardSize * scale,
                             scale: scale)
            .frame(width: min(Constants.productCardSize * scale, Constants.maximumProductCardSize),
                   height: Constants.productCardSize * scale)
            .clipped()

            VStack(alignment: .leading, spacing: Constants.textSpacing) {
                Text(name)
                    .lineLimit(2)
                    .foregroundStyle(Color.posPrimaryText)
                    .multilineTextAlignment(.leading)
                    .font(Constants.itemTitleFont)

                Text(detailText)
                    .foregroundStyle(Color.posSecondaryText)
                    .font(Constants.itemDetailFont)
            }
            .padding(.horizontal, Constants.horizontalTextPadding * (1 / scale))
            .padding(.vertical, Constants.verticalTextPadding * (1 / scale))
            Spacer()
        }
        .frame(maxWidth: .infinity, idealHeight: Constants.productCardSize * scale)
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
