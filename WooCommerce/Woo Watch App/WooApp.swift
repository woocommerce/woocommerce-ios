import SwiftUI

@main
struct Woo_Watch_AppApp: App {

    @StateObject var phoneDependencySynchronizer = PhoneDependenciesSynchronizer()

    var body: some Scene {
        WindowGroup {
            if phoneDependencySynchronizer.dependencies.credentials != nil {
                ContentView()
                    .environment(\.dependencies, phoneDependencySynchronizer.dependencies)
            } else {
                ConnectView()
            }

        }
    }
}
