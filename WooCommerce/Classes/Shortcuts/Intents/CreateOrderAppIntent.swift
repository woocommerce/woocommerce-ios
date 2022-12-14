import AppIntents
import Yosemite
import Foundation

@available(iOS 16, *)
struct CreateOrderAppIntent: AppIntent {
    private let stores: StoresManager = ServiceLocator.stores

    static var title: LocalizedStringResource = "Create Order"
    static var openAppWhenRun = true

    @MainActor // <-- include if the code needs to be run on the main thread
    func perform() async throws -> some IntentResult {
        MainTabBarController.presentOrderCreationFlow()

        return .result()
    }
}
