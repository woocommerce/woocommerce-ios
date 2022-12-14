import AppIntents
import Yosemite
import Foundation

@available(iOS 16, *)
struct OpenOrderAppIntent: AppIntent {
    private let stores: StoresManager = ServiceLocator.stores

    static var title: LocalizedStringResource = "Open Order"
    static var openAppWhenRun = true

    // A dynamic lookup parameter
    @IntentParameter(title: "Order", description: "The order to open in Woo", requestValueDialog: IntentDialog("Which order would you like to open?"))
    var order: ShortcutOrderAppEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Open \(\.$order)")
    }

    @MainActor // <-- include if the code needs to be run on the main thread
    func perform() async throws -> some IntentResult {
        let siteID = stores.sessionManager.defaultStoreID ?? Int64.min
        MainTabBarController.navigateToOrderDetails(with: Int64(order.id), siteID: siteID)

        return .result()

    }
}
