import Foundation
import protocol WooFoundation.Analytics
import UIKit

/// View model for `ProductCreationAIStartingInfoView`.
///
final class ProductCreationAIStartingInfoViewModel: ObservableObject {
    typealias ImageState = EditableImageViewState

    // Image selection
    var onPickPackagePhoto: ((MediaPickingSource) async -> MediaPickerImage?)?

    @Published private(set) var imageState: ImageState
    @Published var isShowingMediaPickerSourceSheet: Bool = false
    @Published var features: String

    let siteID: Int64
    private let analytics: Analytics

    var productFeatures: String? {
        guard features.isNotEmpty else {
            return nil
        }
        return features
    }

    init(siteID: Int64, analytics: Analytics = ServiceLocator.analytics) {
        self.siteID = siteID
        self.features = ""
        self.analytics = analytics
        imageState = .empty
    }

    func didTapReadTextFromPhoto() {
        // TODO: 13103 - Add tracking
        isShowingMediaPickerSourceSheet = true
    }

    func didTapContinue() {
        // TODO: 13103 - Add tracking
    }

    func didTapViewPhoto() {
        // TODO: 13104 - Open image in a new screen
    }

    func didTapReplacePhoto() {
        // TODO: 13103 Add tracking
        isShowingMediaPickerSourceSheet = true
    }

    func didTapRemovePhoto() {
        imageState = .empty
    }

    func selectImage(from source: MediaPickingSource) {
        guard let onPickPackagePhoto else {
            return
        }
        let previousState = imageState
        imageState = .loading
        Task { @MainActor in
            guard let image = await onPickPackagePhoto(source) else {
                return imageState = previousState
            }
            imageState = .success(image)
        }
    }
}
