import Foundation
import Yosemite

/// View model for `ProductSharingMessageGenerationView`
final class ProductSharingMessageGenerationViewModel: ObservableObject {
    let viewTitle: String

    @Published var messageContent: String = ""
    @Published private(set) var generationInProgress: Bool = false

    private let url: String
    private let store: StoresManager

    init(productName: String, url: String, store: StoresManager = ServiceLocator.stores) {
        self.viewTitle = String.localizedStringWithFormat(Localization.title, productName)
        self.url = url
        self.store = store
    }
}

private extension ProductSharingMessageGenerationViewModel {
    enum Localization {
        static let title = NSLocalizedString(
            "Share %1$@",
            comment: "Title of the product sharing message generation screen. " +
            "The placeholder is the name of the product"
        )
    }
}
