import SwiftUI

@main
struct Woo_Watch_AppApp: App {

    @WKApplicationDelegateAdaptor var delegate: AppDelegate

    @StateObject var phoneDependencySynchronizer = PhoneDependenciesSynchronizer()

    @StateObject var appBindings = AppBindings()

    @StateObject var tracksProvider = WatchTracksProvider()

    // Refactor: Include this variable into AppBindings
    @State private var selectedTab = WooWatchTab.myStore

    var body: some Scene {
        WindowGroup {
            Group {
                if let dependencies = phoneDependencySynchronizer.dependencies {
                    NavigationStack {
                        TabView(selection: $selectedTab) {
                            MyStoreView(dependencies: dependencies, watchTab: $selectedTab)
                                .tag(WooWatchTab.myStore)

                            OrdersListView(dependencies: dependencies, watchTab: $selectedTab)
                                .tag(WooWatchTab.ordersList)
                        }
                    }
                    .sheet(item: $appBindings.orderNotification, content: { orderNotification in
                        OrderDetailLoader(dependencies: dependencies, pushNotification: orderNotification)
                    })
                    .compatibleVerticalStyle()
                    .environment(\.dependencies, dependencies)
                    .id(dependencies.storeID) // Forces a redraw when the store id changes

                } else {

                    ConnectView(synchronizer: phoneDependencySynchronizer)

                }
            }
            .environmentObject(tracksProvider)
            .task {
                // For some reason I can't use the bindings directly from our AppDelegate.
                // We need to store them in this type assign them to the delegate for further modification.
                delegate.appBindings = appBindings

                // Assign other delegate dependencies.
                delegate.tracksProvider = tracksProvider
                phoneDependencySynchronizer.tracksProvider = tracksProvider

                // Tracks
                tracksProvider.sendTracksEvent(.watchAppOpened)
            }
        }
    }
}

enum WooWatchTab: Int {
    case myStore
    case ordersList
}

/// Backwards compatible vertical `tabViewStyle` modifier.
///
struct VerticalPageModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(watchOS 10.0, *) {
            content
                .tabViewStyle(.verticalPage)
        } else {
            content
                .tabViewStyle(.carousel)
        }
    }
}

extension View {
    func compatibleVerticalStyle() -> some View {
        self.modifier(VerticalPageModifier())
    }
}
