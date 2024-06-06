import protocol Yosemite.POSItem
import SwiftUI

struct ItemCardView: View {
    private let item: POSItem
    private let onItemCardTapped: (() -> Void)?

    init(item: POSItem, onItemCardTapped: (() -> Void)? = nil) {
        self.item = item
        self.onItemCardTapped = onItemCardTapped
    }

    var body: some View {
        HStack {
            if let imageSource = item.productImageSource {
                ProductImageThumbnail(productImageURL: URL(string: imageSource),
                                      productImageSize: 60,
                                      scale: 1,
                                      productImageCornerRadius: 1,
                                      foregroundColor: .clear)
            } else {
                ProductImageThumbnail(productImageURL: URL(string: ""),
                                      productImageSize: 60,
                                      scale: 1,
                                      productImageCornerRadius: 1,
                                      foregroundColor: .clear)
            }
            VStack {
                Text(item.name)
                    .foregroundStyle(Color.primaryBackground)
                Text(item.price)
                    .foregroundStyle(Color.primaryBackground)
                HStack(spacing: 8) {
                    Spacer()
                    Button(action: {
                        onItemCardTapped?()
                    }, label: { })
                    .buttonStyle(POSPlusButtonStyle())
                    .frame(width: 56, height: 56)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color.tertiaryBackground)
    }
}

#if DEBUG
#Preview {
    ItemCardView(item: POSItemProviderPreview().providePointOfSaleItem(),
                 onItemCardTapped: { })
}
#endif
