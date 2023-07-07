import Photos
import SwiftUI
import Yosemite

/// State of the `EditableImageView`.
enum EditableImageViewState {
    case empty
    case loading
    case success(MediaPickerImage)
    case failure(Error)
}

/// Image selected from the media picker.
struct MediaPickerImage {
    enum Source {
        /// From device camera or photo library.
        case asset(asset: PHAsset)
        /// From site media library.
        case media(media: Media)
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
    private let emptyContent: () -> Content

    init(imageState: EditableImageViewState,
         @ViewBuilder emptyContent: @escaping () -> Content) {
        self.imageState = imageState
        self.emptyContent = emptyContent
    }

    var body: some View {
        switch imageState {
            case .success(let image):
                Image(uiImage: image.image)
                    .resizable()
                    .scaledToFit()
            case .loading:
                ProgressView()
            case .empty:
                emptyContent()
            case .failure(let error):
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text(error.localizedDescription)
                }
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

            EditableImageView(imageState: .failure(ProductDownloadFileError.emptyFileName), emptyContent: {})
                .previewDisplayName("Error state")

            EditableImageView(imageState: .loading, emptyContent: {})
                .previewDisplayName("Loading state")
        }
    }
}
