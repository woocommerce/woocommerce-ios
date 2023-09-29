import Foundation

/// View model for `AddProductNameWithAIView`.
///
final class AddProductNameWithAIViewModel: ObservableObject {
    @Published var productNameContent: String

    let siteID: Int64

    var productName: String? {
        guard productNameContent.isNotEmpty else {
            return nil
        }
        return productNameContent
    }

    init(siteID: Int64) {
        self.siteID = siteID
        self.productNameContent = ""
    }

    func didTapUsePackagePhoto() {
        // Analytics
    }

    func didTapContinue() {
        // Analytics
    }
}
