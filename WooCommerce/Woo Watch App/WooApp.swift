import SwiftUI

@main
struct Woo_Watch_AppApp: App {

    @StateObject var phoneDependencySynchronizer = PhoneDependenciesSynchronizer()

    var body: some Scene {
        WindowGroup {
            ContentView(message: phoneDependencySynchronizer.message)
        }
    }
}
