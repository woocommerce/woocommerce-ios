import Photos
import SwiftUI
import Yosemite

/// State of the `EditableImageView`.
enum EditableImageViewState: Equatable {
    case empty
    case loading
    case success(MediaPickerImage)
}

/// Image selected from the media picker.
struct MediaPickerImage: Equatable {
    enum Source: Equatable {
        /// From device camera or photo library.
        case asset(asset: PHAsset)
        /// From site media library.
        case media(media: Media)
        /// From product image.
        case productImage(image: ProductImage)
    }

    let image: UIImage
    let source: Source

    init(image: UIImage, source: Source) {
        self.image = image
        self.source = source
    }
}

/// A view that hosts a mutable image in different states.
struct EditableImageView<Content: View>: View {
    private let imageState: EditableImageViewState
    private let aspectRatio: ContentMode
    private let emptyContent: () -> Content

    init(imageState: EditableImageViewState,
         aspectRatio: ContentMode = .fit,
         @ViewBuilder emptyContent: @escaping () -> Content) {
        self.imageState = imageState
        self.aspectRatio = aspectRatio
        self.emptyContent = emptyContent
    }

    var body: some View {
        switch imageState {
            case .success(let image):
                Image(uiImage: image.image)
                    .resizable()
                    .aspectRatio(contentMode: aspectRatio)
            case .loading:
                ProgressView()
            case .empty:
                emptyContent()
        }
    }
}

extension EditableImageViewState {
    var image: MediaPickerImage? {
        guard case let .success(image) = self else {
            return nil
        }
        return image
    }
}

struct EditableImageView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            EditableImageView(imageState: .success(
                .init(image: .prologueWooMobileImage,
                      source: .asset(asset: .init()))),
                              emptyContent: {})
            .previewDisplayName("Image state")

            EditableImageView(imageState: .empty,
                              emptyContent: {
                Text("Empty")
            })
            .previewDisplayName("Empty state")

            EditableImageView(imageState: .loading, emptyContent: {})
                .previewDisplayName("Loading state")
        }
    }
}
