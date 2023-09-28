import Foundation

/// View model for `AddProductNameWithAIView`.
///
final class AddProductNameWithAIViewModel: ObservableObject {
    @Published var productNameContent: String

    let siteID: Int64
    private let analytics: Analytics
    private let onUsePackagePhoto: (String?) -> Void
    private let onContinueWithProductName: (String) -> Void

    private var productName: String? {
        guard productNameContent.isNotEmpty else {
            return nil
        }
        return productNameContent
    }

    init(siteID: Int64,
         initialName: String = "",
         analytics: Analytics = ServiceLocator.analytics,
         onUsePackagePhoto: @escaping (String?) -> Void,
         onContinueWithProductName: @escaping (String) -> Void) {
        self.siteID = siteID
        self.onUsePackagePhoto = onUsePackagePhoto
        self.onContinueWithProductName = onContinueWithProductName
        self.productNameContent = initialName
        self.analytics = analytics
    }

    func didTapUsePackagePhoto() {
        onUsePackagePhoto(productName)
    }

    func didTapSuggestName() {
        analytics.track(event: .ProductNameAI.entryPointTapped(hasInputName: productNameContent.isNotEmpty, source: .productCreationAI))
    }

    func didTapContinue() {
        analytics.track(event: .ProductCreationAI.productNameContinueTapped())
        onContinueWithProductName(productNameContent)
    }
}
