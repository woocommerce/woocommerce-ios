import protocol Yosemite.POSItem
import SwiftUI

struct ItemCardView: View {
    private let item: POSItem

    @ScaledMetric private var scale: CGFloat = 1.0

    init(item: POSItem) {
        self.item = item
    }

    private var commaSeparatedItemCategories: String {
        item.itemCategories.prefix(Constants.maxNumberOfCategories).joined(separator: ", ")
    }

    var body: some View {
        HStack {
            if let imageSource = item.productImageSource {
                ProductImageThumbnail(productImageURL: URL(string: imageSource),
                                      productImageSize: Constants.productImageWidth,
                                      scale: scale,
                                      productImageCornerRadius: Constants.productImageCornerRadius,
                                      foregroundColor: .clear)
            } else {
                // TODO:
                // Handle what we'll show when there's lack of images:
                Rectangle()
                    .frame(width: Constants.productImageWidth * scale,
                           height: Constants.productImageWidth * scale)
                    .foregroundColor(.gray)
            }
            VStack(alignment: .leading) {
                Text(item.name)
                    .foregroundStyle(Color.posPrimaryTexti3)
                Text(commaSeparatedItemCategories)
                    .foregroundStyle(Color.posPrimaryTexti3)
            }
            Spacer()
            Text(item.price)
                .foregroundStyle(Color.posPrimaryTexti3)
        }
        .frame(maxWidth: .infinity)
        .background(Color.posBackgroundWhitei3)
    }
}

private extension ItemCardView {
    enum Constants {
        static let productImageWidth: CGFloat = 60
        static let productImageCornerRadius: CGFloat = 0
        static let maxNumberOfCategories = 3
    }
}

#if DEBUG
#Preview {
    ItemCardView(item: POSItemProviderPreview().providePointOfSaleItem())
}
#endif
