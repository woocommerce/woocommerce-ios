import SwiftUI

@main
struct Woo_Watch_AppApp: App {

    @StateObject var phoneDependencySynchronizer = PhoneDependenciesSynchronizer()

    var body: some Scene {
        WindowGroup {
            if let dependencies = phoneDependencySynchronizer.dependencies {
                MyStoreView(dependencies: dependencies)
                    .environment(\.dependencies, dependencies)
            } else {
                ConnectView()
            }
        }
    }
}
