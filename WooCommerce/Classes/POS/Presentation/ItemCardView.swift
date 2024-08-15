import protocol Yosemite.POSItem
import SwiftUI

struct ItemCardView: View {
    private let item: POSItem

    @ScaledMetric private var scale: CGFloat = 1.0

    init(item: POSItem) {
        self.item = item
    }

    var body: some View {
        HStack(spacing: Constants.horizontalCardSpacing) {
            if let imageSource = item.productImageSource {
                ProductImageThumbnail(productImageURL: URL(string: imageSource),
                                      productImageSize: Constants.productCardHeight,
                                      scale: scale,
                                      foregroundColor: .clear)
            } else {
                // TODO:
                // Handle what we'll show when there's lack of images:
                Rectangle()
                    .frame(width: Constants.productCardHeight * scale,
                           height: Constants.productCardHeight * scale)
                    .foregroundColor(.gray)
            }
            Text(item.name)
                .foregroundStyle(Color.posPrimaryTexti3)
                .multilineTextAlignment(.leading)
                .font(Constants.itemNameFont)
                .padding(.horizontal, Constants.horizontalElementSpacing)
            Spacer()
            Text(item.formattedPrice)
                .foregroundStyle(Color.posPrimaryTexti3)
                .font(Constants.itemPriceFont)
                .padding()
        }
        .frame(maxWidth: .infinity, idealHeight: Constants.productCardHeight)
        .background(Color.posBackgroundWhitei3)
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
        static let productCardHeight: CGFloat = 112
        static let productCardCornerRadius: CGFloat = 8
        static let productImageCornerRadius: CGFloat = 0
        // The use of stroke means the shape is rendered as an outline (border) rather than a filled shape,
        // since we still have to give it a value, we use 0 so it renders no border but it's shaped as one.
        static let nilOutline: CGFloat = 0
        static let horizontalCardSpacing: CGFloat = 0
        static let horizontalElementSpacing: CGFloat = 32
        static let itemNameFont: POSFontStyle = .posBodyEmphasized
        static let itemPriceFont: POSFontStyle = .posBodyRegular
    }
}

#if DEBUG
#Preview {
    ItemCardView(item: POSItemProviderPreview().providePointOfSaleItem())
}
#endif
