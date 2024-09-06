import protocol Yosemite.POSItem
import SwiftUI

struct ItemCardView: View {
    private let item: POSItem

    @ScaledMetric private var scale: CGFloat = 1.0

    init(item: POSItem) {
        self.item = item
    }

    var body: some View {
        HStack(spacing: Constants.cardSpacing) {
            if let imageSource = item.productImageSource {
                ProductImageThumbnail(productImageURL: URL(string: imageSource),
                                      productImageSize: Constants.productCardSize * scale,
                                      scale: scale,
                                      foregroundColor: .clear)
                .frame(width: min(Constants.productCardSize * scale, Constants.maximumProductCardSize),
                       height: Constants.productCardSize * scale)
                .clipped()
            } else {
                Rectangle()
                    .frame(width: min(Constants.productCardSize * scale, Constants.maximumProductCardSize),
                           height: Constants.productCardSize * scale)
                    .foregroundColor(Color(.secondarySystemFill))
            }

            DynamicHStack(spacing: Constants.textSpacing) {
                Text(item.name)
                    .foregroundStyle(Color.posPrimaryText)
                    .multilineTextAlignment(.leading)
                    .font(Constants.itemNameFont)
                Spacer()
                Text(item.formattedPrice)
                    .foregroundStyle(Color.posPrimaryText)
                    .font(Constants.itemPriceFont)
            }
            .padding(Constants.textPadding)
            Spacer()
        }
        .frame(maxWidth: .infinity, idealHeight: Constants.productCardSize * scale)
        .background(Color.posSecondaryBackground)
        .overlay {
            RoundedRectangle(cornerRadius: Constants.productCardCornerRadius)
                .stroke(Color.black, lineWidth: Constants.nilOutline)
        }
        .clipShape(RoundedRectangle(cornerRadius: Constants.productCardCornerRadius))
        .shadow(color: Color.black.opacity(0.08), radius: 4, y: 2)
    }
}

private extension ItemCardView {
    enum Constants {
        static let productCardSize: CGFloat = 112
        static let maximumProductCardSize: CGFloat = Constants.productCardSize * 2
        static let productCardCornerRadius: CGFloat = 8
        // The use of stroke means the shape is rendered as an outline (border) rather than a filled shape,
        // since we still have to give it a value, we use 0 so it renders no border but it's shaped as one.
        static let nilOutline: CGFloat = 0
        static let cardSpacing: CGFloat = 0
        static let textSpacing: CGFloat = 8
        static let textPadding: CGFloat = 32
        static let itemNameFont: POSFontStyle = .posBodyEmphasized
        static let itemPriceFont: POSFontStyle = .posBodyRegular
    }
}

#if DEBUG
#Preview {
    ItemCardView(item: POSItemProviderPreview().providePointOfSaleItem())
}
#endif
