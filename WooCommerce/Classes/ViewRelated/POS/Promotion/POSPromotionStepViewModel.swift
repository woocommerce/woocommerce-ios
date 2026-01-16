import Foundation

/// View model for an individual step in the POS Promotion modal.
///
struct POSPromotionStepViewModel {
    let title: String
    let description: String
    let imageName: String

    init(title: String, description: String, imageName: String) {
        self.title = title
        self.description = description
        self.imageName = imageName
    }
}
