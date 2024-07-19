import Foundation
import protocol WooFoundation.Analytics
import UIKit
import Combine
import Experiments

/// View model for `ProductCreationAIStartingInfoView`.
///
final class ProductCreationAIStartingInfoViewModel: ObservableObject {
    typealias ImageState = EditableImageViewState

    // Image selection
    var onPickPackagePhoto: ((MediaPickingSource) async -> MediaPickerImage?)?

    @Published private(set) var imageState: ImageState
    @Published var isShowingMediaPickerSourceSheet = false
    @Published var isShowingViewPhotoSheet = false
    @Published var features: String

    @Published var notice: Notice?

    /// Text detection
    @Published private(set) var textDetectionErrorMessage: String? = nil

    let siteID: Int64
    private let analytics: Analytics
    private let imageTextScanner: ImageTextScannerProtocol
    private var subscriptions: Set<AnyCancellable> = []
    let featureFlagService: FeatureFlagService

    var productFeatures: String? {
        guard features.isNotEmpty else {
            return nil
        }
        return features
    }

    init(siteID: Int64,
         imageTextScanner: ImageTextScannerProtocol = ImageTextScanner(),
         analytics: Analytics = ServiceLocator.analytics,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        self.siteID = siteID
        self.features = ""
        self.imageTextScanner = imageTextScanner
        self.analytics = analytics
        self.featureFlagService = featureFlagService
        imageState = .empty
        listenToImageStateAndClearTextDetectionError()
    }

    func didTapReadTextFromPhoto() {
        analytics.track(event: .ProductCreationAI.packagePhotoSelectionFlowStarted())
        isShowingMediaPickerSourceSheet = true
    }

    func didTapViewPhoto() {
        isShowingViewPhotoSheet = true
    }

    func didTapReplacePhoto() {
        analytics.track(event: .ProductCreationAI.packagePhotoSelectionFlowStarted())
        isShowingMediaPickerSourceSheet = true
    }

    func didTapRemovePhoto() {
        let previousState = imageState
        imageState = .empty
        notice = Notice(title: Localization.PhotoRemovedNotice.title,
                        feedbackType: .success,
                        actionTitle: Localization.PhotoRemovedNotice.undo,
                        actionHandler: { [weak self, previousState] in
            self?.imageState = previousState
        })
    }

    @MainActor
    func selectImage(from source: MediaPickingSource) async {
        guard let onPickPackagePhoto else {
            return
        }
        let previousState = imageState
        imageState = .loading

        guard let image = await onPickPackagePhoto(source) else {
            return imageState = previousState
        }

        await detectTexts(from: image.image)

        imageState = .success(image)
    }
}

private extension ProductCreationAIStartingInfoViewModel {
    @MainActor
    func detectTexts(from image: UIImage) async {
        do {
            let texts = try await imageTextScanner.scanText(from: image)
            if texts.isEmpty {
                throw ScanError.noTextDetected
            }
            self.features = texts.joined(separator: " ")
            analytics.track(event: .ProductCreationAI.packagePhotoTextDetected(wordCount: texts.count))
        } catch {
            analytics.track(event: .ProductCreationAI.packagePhotoTextDetectionFailed(error: error))
            switch error {
            case ScanError.noTextDetected:
                textDetectionErrorMessage = Localization.noTextDetected
                DDLogError("⛔️ No text detected from image.")
            default:
                textDetectionErrorMessage = Localization.textDetectionFailed
                DDLogError("⛔️ Error scanning text from image: \(error)")
            }
        }
    }

    func listenToImageStateAndClearTextDetectionError() {
        $imageState
            .removeDuplicates()
            .sink(receiveValue: { [weak self] imageState in
                guard let self else { return }
                switch imageState {
                case .success:
                    return
                case .empty, .loading:
                    textDetectionErrorMessage = nil
                }
            })
            .store(in: &subscriptions)
    }
}

extension ProductCreationAIStartingInfoViewModel {
    enum Localization {
        static let noTextDetected = NSLocalizedString(
            "productCreationAIStartingInfoViewModel.noTextDetected",
            value: "No text detected. Please select another packaging photo or enter product details manually.",
            comment: "No text detected message while adding package photo in the starting information screen."
        )
        static let textDetectionFailed = NSLocalizedString(
            "productCreationAIStartingInfoViewModel.textDetectionFailed",
            value: "An error occurred while scanning the photo. Please select another packaging photo or enter product details manually.",
            comment: "Text detection failed error message on the starting information screen."
        )
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

    enum ScanError: Error {
        case noTextDetected
    }
}
