import protocol Yosemite.POSItem
import SwiftUI

struct ItemCardView: View {
    private let item: POSItem
    private let onItemCardTapped: (() -> Void)?

    @ScaledMetric private var scale: CGFloat = 1.0

    init(item: POSItem, onItemCardTapped: (() -> Void)? = nil) {
        self.item = item
        self.onItemCardTapped = onItemCardTapped
    }

    var commaSeparatedItemCategories: String {
        let maxNumberOfCategories = 3
        return item.itemCategories.prefix(maxNumberOfCategories).joined(separator: ", ")
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
                    .foregroundStyle(Color.primaryBackground)
                Text(commaSeparatedItemCategories)
                    .foregroundStyle(Color.primaryBackground)
            }
            Spacer()
            Text(item.price)
                .foregroundStyle(Color.primaryBackground)
        }
        .frame(maxWidth: .infinity)
        .background(Color.tertiaryBackground)
    }
}

private extension ItemCardView {
    enum Constants {
        static let productImageWidth: CGFloat = 60
        static let productImageCornerRadius: CGFloat = 0
    }
}

#if DEBUG
#Preview {
    ItemCardView(item: POSItemProviderPreview().providePointOfSaleItem(),
                 onItemCardTapped: { })
}
#endif
