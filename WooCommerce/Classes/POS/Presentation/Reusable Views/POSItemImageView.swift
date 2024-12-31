import SwiftUI

/// A view that displays an image in a POS item view.
struct POSItemImageView: View {
    let imageSource: String?
    let imageSize: CGFloat
    let scale: CGFloat

    var body: some View {
        if let imageSource = imageSource {
            ProductImageThumbnail(productImageURL: URL(string: imageSource),
                                  productImageSize: imageSize,
                                  scale: scale,
                                  foregroundColor: .clear,
                                  cachesOriginalImage: true)
        } else {
            Rectangle()
                .foregroundColor(Color(.secondarySystemFill))
        }
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
