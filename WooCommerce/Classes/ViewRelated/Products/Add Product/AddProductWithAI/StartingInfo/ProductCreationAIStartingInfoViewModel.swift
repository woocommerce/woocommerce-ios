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
    @Published var isShowingViewPhotoSheet: Bool = false
    @Published var features: String

    @Published var notice: Notice?

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
        isShowingViewPhotoSheet = true
    }

    func didTapReplacePhoto() {
        // TODO: 13103 Add tracking
        isShowingMediaPickerSourceSheet = true
    }

    func didTapRemovePhoto() {
        let previousState = imageState
        imageState = .empty
        notice = Notice(title: Localization.PhotoRemovedNotice.title,
                        feedbackType: .success,
                        actionTitle: Localization.PhotoRemovedNotice.undo,
                        actionHandler: { [weak self] in
            self?.imageState = previousState
        })
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

private extension ProductCreationAIStartingInfoViewModel {
    enum Localization {
        enum PhotoRemovedNotice {
            static let title = NSLocalizedString(
                "productCreationAIStartingInfoViewModel.photoRemovedNotice.title",
                value: "Photo removed",
                comment: "Title of the notice that confirms that the package photo is removed."
            )
            static let undo = NSLocalizedString(
                "productCreationAIStartingInfoViewModel.photoRemovedNotice.undo",
                value: "Undo",
                comment: "Button to undo the package photo removal action."
            )
        }
    }
}
