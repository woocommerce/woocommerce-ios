import AppIntents
import Yosemite
import Foundation

@available(iOS 16, *)
struct MarkOrderAsCompletedAppIntent: AppIntent {
    private let stores: StoresManager = ServiceLocator.stores

    static var title: LocalizedStringResource = "Mark order as completed"

    // A dynamic lookup parameter
    @IntentParameter(title: "Order", description: "The order to mark as completed",
                     requestValueDialog: IntentDialog("Which order would you like to mark as completed?"))
    var order: ShortcutOrderAppEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Mark \(\.$order) as completed")
    }

    @MainActor // <-- include if the code needs to be run on the main thread
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let siteID = stores.sessionManager.defaultStoreID ?? Int64.min
        debugPrint("site id \(siteID) order id \(order.id)")

        let dialog = await withCheckedContinuation { continuation in
            let action = OrderAction.updateOrderStatus(siteID: siteID, orderID: Int64(order.id), status: .completed) { error in
                let dialogMessage = error == nil ? "Order was marked as completed succesfully.": "Order couldn't be marked as completed"

                continuation.resume(returning: dialogMessage)
            }

            stores.dispatch(action)
        }

        return .result(dialog: IntentDialog(stringLiteral: dialog))
    }
}
