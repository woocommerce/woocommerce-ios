import SwiftUI
import struct WooFoundation.ProductImageThumbnail

enum POSItemImageState {
    case normal
    case error
}

/// A view that displays an image in a POS item view.
struct POSItemImageView: View {
    let imageSource: String?
    let imageSize: CGFloat
    let scale: CGFloat
    var state: POSItemImageState = .normal

    private var placeholderView: some View {
        Rectangle()
            .foregroundColor(foregroundColor)
            .overlay {
                Image(systemName: "archivebox")
                    .accessibilityHidden(true)
                    .font(.posButtonSymbolLarge)
                    .foregroundColor(imageColor)
            }
    }

    var body: some View {
        if let imageSource {
            ProductImageThumbnail(productImageURL: URL(string: imageSource),
                                  productImageSize: imageSize,
                                  scale: scale,
                                  foregroundColor: imageColor,
                                  cachesOriginalImage: true) {
                placeholderView
            }
        } else {
            placeholderView
        }
    }

    private var foregroundColor: Color {
        switch state {
        case .normal:
            return .posSurfaceDim
        case .error:
            return .posError
        }
    }

    private var imageColor: Color {
        switch state {
        case .normal:
            return .posOnSurfaceVariantLowest
        case .error:
            return .posOnError
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
