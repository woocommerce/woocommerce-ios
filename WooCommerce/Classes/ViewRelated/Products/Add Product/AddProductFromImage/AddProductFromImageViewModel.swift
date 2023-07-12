import Combine
import SwiftUI
import Yosemite

/// View model for `AddProductFromImageView` to handle user actions from the view and provide data for the view.
@MainActor
final class AddProductFromImageViewModel: ObservableObject {
    typealias ImageState = EditableImageViewState

    // MARK: - Product Details

    @Published var name: String = ""
    @Published var description: String = ""

    // MARK: - Product Image

    @Published private(set) var imageState: ImageState = .empty
    var image: MediaPickerImage? {
        imageState.image
    }

    private let onAddImage: (MediaPickingSource) async -> MediaPickerImage?
    private var selectedImageSubscription: AnyCancellable?

    init(onAddImage: @escaping (MediaPickingSource) async -> MediaPickerImage?) {
        self.onAddImage = onAddImage

        selectedImageSubscription = $imageState.compactMap { $0.image?.image }
        .sink { [weak self] image in
            self?.onSelectedImage(image)
        }
    }

    /// Invoked after the user selects a media source to add an image.
    /// - Parameter source: Source of the image.
    func addImage(from source: MediaPickingSource) {
        let previousState = imageState
        imageState = .loading
        Task { @MainActor in
            guard let image = await onAddImage(source) else {
                return imageState = previousState
            }
            imageState = .success(image)
        }
    }
}

private extension AddProductFromImageViewModel {
    func onSelectedImage(_ image: UIImage) {
        // TODO: 10180 - scan texts from the image
    }
}
