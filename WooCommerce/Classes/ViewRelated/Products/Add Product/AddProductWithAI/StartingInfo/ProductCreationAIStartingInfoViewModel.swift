import Foundation
import protocol WooFoundation.Analytics
import UIKit

/// View model for `ProductCreationAIStartingInfoView`.
///
final class ProductCreationAIStartingInfoViewModel: ObservableObject {
    @Published var features: String
    @Published private var packageMedia: MediaPickerImage?

    let siteID: Int64
    private let analytics: Analytics

    var packagePhoto: UIImage? {
        packageMedia?.image
    }

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
    }

    func didTapReadTextFromPhoto() {
        // TODO: 13103 - Add tracking
    }

    func didTapContinue() {
        // TODO: 13103 - Add tracking
    }

    func onSelectImage(_ image: MediaPickerImage?) {
        self.packageMedia = image
    }

    func didTapViewPhoto() {
        // TODO: 13104 - Open image in a new screen
    }

    func didTapReplacePhoto() {
        // TODO: 13103 Add tracking
    }

    func didTapRemovePhoto() {
        packageMedia = nil
    }
}
