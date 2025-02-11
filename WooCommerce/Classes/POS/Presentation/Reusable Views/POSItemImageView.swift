import SwiftUI

/// A view that displays an image in a POS item view.
struct POSItemImageView: View {
    let imageSource: String?
    let imageSize: CGFloat
    let scale: CGFloat

    var body: some View {
        if let imageSource {
            ProductImageThumbnail(productImageURL: URL(string: imageSource),
                                  productImageSize: imageSize,
                                  scale: scale,
                                  foregroundColor: Constants.placeholderIconColor,
                                  cachesOriginalImage: true)
        } else {
            Rectangle()
                .foregroundColor(Constants.placeholderBackgroundColor)
                .overlay {
                    Text(Image(systemName: "archivebox"))
                        .font(.posButtonSymbol)
                        .foregroundColor(Constants.placeholderIconColor)
                }
        }
    }
}

private extension POSItemImageView {
    enum Constants {
        static let placeholderIconDimension: CGFloat = 38
        static let placeholderIconColor: Color = .posOnSurfaceVariantLowest
        static let placeholderBackgroundColor: Color = .posSurfaceDim
    }
}

#Preview("Placeholder") {
    POSItemImageView(imageSource: nil,
                     imageSize: 112,
                     scale: 1)
}

#Preview("Image") {
    POSItemImageView(imageSource: "https://pd.w.org/2024/12/986762d0d4d4cf17.82435881-scaled.jpeg",
                     imageSize: 112,
                     scale: 1)
}
