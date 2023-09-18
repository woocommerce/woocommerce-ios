import Foundation

/// View model for `AddProductNameWithAIView`.
///
final class AddProductNameWithAIViewModel: ObservableObject {
    @Published var productNameContent: String = ""
    private let onUsePackagePhoto: (String?) -> Void
    private let onContinueWithProductName: (String) -> Void

    private var productName: String? {
        guard productNameContent.isNotEmpty else {
            return nil
        }
        return productNameContent
    }

    init(siteID: Int64,
         onUsePackagePhoto: @escaping (String?) -> Void,
         onContinueWithProductName: @escaping (String) -> Void) {
        self.onUsePackagePhoto = onUsePackagePhoto
        self.onContinueWithProductName = onContinueWithProductName
    }

    func didTapUsePackagePhoto() {
        onUsePackagePhoto(productName)
    }

    func didTapSuggestName() {
        // TODO: Present suggest name sheet
    }

    func didTapContinue() {
        onContinueWithProductName(productNameContent)
    }
}
