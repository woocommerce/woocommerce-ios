import Foundation
import Yosemite

/// View model for `ProductSharingMessageGenerationView`
final class ProductSharingMessageGenerationViewModel: ObservableObject {
    @Published var isSharePopoverPresented = false
    @Published var isShareSheetPresented = false

    let viewTitle: String

    var generateButtonTitle: String {
        messageContent.isEmpty ? Localization.generate : Localization.regenerate
    }

    var generateButtonImageName: String {
        messageContent.isEmpty ? "sparkles" : "arrow.counterclockwise"
    }

    var shareSheet: ShareSheet {
        let activityItems: [Any]
        if let url = URL(string: url) {
            activityItems = [messageContent, url]
        } else {
            activityItems = [messageContent]
        }
        return ShareSheet(activityItems: activityItems)
    }

    @Published var messageContent: String = ""
    @Published private(set) var generationInProgress: Bool = false
    @Published private(set) var errorMessage: String?

    private let siteID: Int64
    private let url: String
    private let productName: String
    private let productDescription: String
    private let stores: StoresManager
    private let isPad: Bool

    init(siteID: Int64,
         url: String,
         productName: String,
         productDescription: String,
         isPad: Bool = UIDevice.isPad(),
         stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.url = url
        self.productName = productName
        self.productDescription = productDescription
        self.isPad = isPad
        self.stores = stores
        self.viewTitle = String.localizedStringWithFormat(Localization.title, productName)
    }

    @MainActor
    func generateShareMessage() async {
        // TODO: Analytics
        errorMessage = nil
        generationInProgress = true
        do {
            messageContent = try await requestMessageFromAI()
            // TODO: Analytics
        } catch {
            // TODO: Analytics
            DDLogError("⛔️ Error generating product sharing message: \(error)")
            errorMessage = Localization.errorMessage
        }
        generationInProgress = false
    }

    func didTapShare() {
        if isPad {
            isSharePopoverPresented = true
        } else {
            isShareSheetPresented = true
        }
    }
}

private extension ProductSharingMessageGenerationViewModel {
    @MainActor
    func requestMessageFromAI() async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(ProductAction.generateProductSharingMessage(siteID: siteID,
                                                                        url: url,
                                                                        name: productName,
                                                                        description: productDescription,
                                                                        languageCode: Locale.current.identifier,
                                                                        completion: { result in
                continuation.resume(with: result)
            }))
        }
    }
}

extension ProductSharingMessageGenerationViewModel {
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
        static let generate = NSLocalizedString(
            "Write it for me",
            comment: "Action button to generate message on the product sharing message generation screen"
        )
        static let regenerate = NSLocalizedString(
            "Regenerate",
            comment: "Action button to regenerate message on the product sharing message generation screen"
        )
    }
}
