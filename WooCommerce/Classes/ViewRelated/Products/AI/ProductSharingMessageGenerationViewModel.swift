import Foundation
import Yosemite

/// View model for `ProductSharingMessageGenerationView`
final class ProductSharingMessageGenerationViewModel: ObservableObject {
    let viewTitle: String

    @Published var messageContent: String = ""
    @Published private(set) var generationInProgress: Bool = false
    @Published private(set) var errorMessage: String?

    private let siteID: Int64
    private let url: String
    private let store: StoresManager

    init(siteID: Int64,
         productName: String,
         url: String,
         store: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.url = url
        self.store = store
        self.viewTitle = String.localizedStringWithFormat(Localization.title, productName)
    }

    @MainActor
    func generateShareMessage() async {
        errorMessage = nil
        generationInProgress = true
        do {
            self.messageContent = try await withCheckedThrowingContinuation { continuation in
                store.dispatch(ProductAction.generateProductSharingMessage(siteID: siteID,
                                                                           url: url,
                                                                           languageCode: Locale.current.identifier,
                                                                           completion: { result in
                    continuation.resume(with: result)
                }))
            }
        } catch {
            DDLogError("⛔️ Error generating product sharing message: \(error)")
            errorMessage = Localization.errorMessage
        }
        generationInProgress = false
    }
}

private extension ProductSharingMessageGenerationViewModel {
    enum Localization {
        static let title = NSLocalizedString(
            "Share %1$@",
            comment: "Title of the product sharing message generation screen. " +
            "The placeholder is the name of the product"
        )
        static let errorMessage = NSLocalizedString(
            "Error generating message. Please try again.",
            comment: "Error message on the product sharing message generation screen when generation fails."
        )
    }
}
