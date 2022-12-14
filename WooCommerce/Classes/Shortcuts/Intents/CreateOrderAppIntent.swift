import AppIntents
import Yosemite
import Foundation

@available(iOS 16, *)
struct CreateOrderWithProductAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Create Order with a Product"
    static var openAppWhenRun = true

    @IntentParameter(title: "Product", description: "The product to add to the order", requestValueDialog: IntentDialog("Which product would you like to add to the order?"))
    var product: ShortcutProductAppEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Create order with \(\.$product)")
    }

    @MainActor // <-- include if the code needs to be run on the main thread
    func perform() async throws -> some IntentResult {
        MainTabBarController.presentOrderCreationFlow(with: product.originalProduct)

        return .result()
    }
}

@available(iOS 16, *)
struct CreateEmptyOrderAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Create Order"
    static var openAppWhenRun = true

    @MainActor // <-- include if the code needs to be run on the main thread
    func perform() async throws -> some IntentResult {
        MainTabBarController.presentOrderCreationFlow()

        return .result()
    }
}
