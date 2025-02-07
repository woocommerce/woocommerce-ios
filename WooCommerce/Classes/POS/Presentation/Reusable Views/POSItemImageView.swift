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
                                  foregroundColor: Constants.placeholderColor,
                                  cachesOriginalImage: true)
        } else {
            Rectangle()
                .foregroundColor(.posSurfaceContainerLowest)
                .overlay {
                    Image(systemName: "archivebox")
                        .resizable()
                        .frame(width: Constants.placeholderDimension, height: Constants.placeholderDimension)
                        .foregroundColor(Constants.placeholderColor)
                }
        }
    }
}

private extension POSItemImageView {
    enum Constants {
        static let placeholderDimension: CGFloat = 48
        static let placeholderColor: Color = .posOnDisabledContainer
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
