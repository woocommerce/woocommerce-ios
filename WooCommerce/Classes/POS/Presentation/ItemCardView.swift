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
